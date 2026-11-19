#!/bin/bash
# BeforeInstall hook: make sure the Node.js runtime and the app's service user exist.
# Idempotent - does nothing if everything is already in place.
set -euo pipefail

NODE_MAJOR=22
NODE_DIR=/opt/nodejs

# 1. Node.js LTS from nodejs.org, verified against the official SHA-256 checksums
if [ ! -x "$NODE_DIR/bin/node" ] || [[ "$("$NODE_DIR/bin/node" --version)" != "v$NODE_MAJOR."* ]]; then
  case "$(uname -m)" in
    x86_64)  ARCH=x64 ;;
    aarch64) ARCH=arm64 ;;
    *) echo "Unsupported CPU architecture: $(uname -m)" >&2; exit 1 ;;
  esac

  BASE_URL="https://nodejs.org/dist/latest-v$NODE_MAJOR.x"
  WORK_DIR=$(mktemp -d)
  trap 'rm -rf "$WORK_DIR"' EXIT

  curl -fsSL "$BASE_URL/SHASUMS256.txt" -o "$WORK_DIR/SHASUMS256.txt"
  TARBALL=$(awk -v arch="$ARCH" '$2 ~ ("-linux-" arch "\\.tar\\.gz$") { print $2 }' "$WORK_DIR/SHASUMS256.txt")
  if [ -z "$TARBALL" ]; then
    echo "Could not find a Node.js $NODE_MAJOR tarball for linux-$ARCH" >&2
    exit 1
  fi

  echo "Installing $TARBALL"
  curl -fsSL "$BASE_URL/$TARBALL" -o "$WORK_DIR/$TARBALL"
  (cd "$WORK_DIR" && grep " $TARBALL\$" SHASUMS256.txt | sha256sum --check --strict -)

  rm -rf "$NODE_DIR"
  mkdir -p "$NODE_DIR"
  tar -xzf "$WORK_DIR/$TARBALL" -C "$NODE_DIR" --strip-components=1 --no-same-owner
  ln -sf "$NODE_DIR/bin/node" /usr/local/bin/node
  ln -sf "$NODE_DIR/bin/npm" /usr/local/bin/npm
fi
"$NODE_DIR/bin/node" --version

# 2. Unprivileged user that runs the app (no login shell, no home directory)
if ! id nodeapp >/dev/null 2>&1; then
  useradd --system --no-create-home --home-dir /opt/nodeapp --shell /sbin/nologin nodeapp
fi

mkdir -p /opt/nodeapp
