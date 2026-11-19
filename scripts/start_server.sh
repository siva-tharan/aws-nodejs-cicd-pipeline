#!/bin/bash
# ApplicationStart hook: (re)start the app under systemd and enable it at boot.
set -euo pipefail

systemctl enable nodeapp.service
systemctl restart nodeapp.service
