#!/bin/bash
# AfterInstall hook: install production dependencies, record deployment details,
# fix ownership, and install the systemd unit.
set -euo pipefail

APP_DIR=/opt/nodeapp
export PATH="/opt/nodejs/bin:$PATH"
export HOME="${HOME:-/root}"
export npm_config_cache=/var/cache/nodeapp-npm

cd "$APP_DIR"

# Exact versions from package-lock.json, without dev dependencies
npm ci --omit=dev --no-audit --no-fund

# Shown on the home page and at /api/info, so you can see which deployment is live
cat > "$APP_DIR/deploy-info.json" <<EOF
{
  "deploymentId": "${DEPLOYMENT_ID:-unknown}",
  "deploymentGroup": "${DEPLOYMENT_GROUP_NAME:-unknown}",
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# The app only needs to read its files
chown -R root:nodeapp "$APP_DIR"
chmod -R u=rwX,g=rX,o= "$APP_DIR"

install -m 0644 "$APP_DIR/config/nodeapp.service" /etc/systemd/system/nodeapp.service
systemctl daemon-reload
