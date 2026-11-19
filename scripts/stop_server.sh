#!/bin/bash
# ApplicationStop hook. CodeDeploy runs this from the previous revision, so it must
# succeed even when the service doesn't exist yet (first deployment).
systemctl stop nodeapp.service 2>/dev/null || true
exit 0
