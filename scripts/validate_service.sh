#!/bin/bash
# ValidateService hook: the deployment only succeeds if /health answers.
# If it fails, CodeDeploy marks the deployment failed and rolls back automatically.
set -euo pipefail

URL="http://127.0.0.1/health"

for attempt in $(seq 1 15); do
  if curl -fsS --max-time 2 "$URL" | grep -q '"status":"ok"'; then
    echo "Health check passed on attempt $attempt"
    exit 0
  fi
  echo "Waiting for the app (attempt $attempt)..."
  sleep 2
done

echo "Health check failed: $URL did not return status ok" >&2
journalctl -u nodeapp.service --no-pager -n 50 >&2 || true
exit 1
