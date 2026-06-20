#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: pfassina
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/openclaw/openclaw

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl sudo mc git
msg_ok "Installed Dependencies"

NODE_VERSION="24" NODE_MODULE="openclaw" setup_nodejs

msg_info "Setup OpenClaw"
mkdir -p /root/.openclaw
GATEWAY_TOKEN=$(openssl rand -hex 16)
cat <<CONF >/root/.openclaw/openclaw.json
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": 18789,
    "auth": {
      "mode": "token",
      "token": "${GATEWAY_TOKEN}"
    }
  }
}
CONF
{
  echo "OpenClaw Gateway"
  echo "URL: http://<container-ip>:18789"
  echo "Auth Token: ${GATEWAY_TOKEN}"
} >>~/openclaw.creds
msg_ok "Setup OpenClaw"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/openclaw.service
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/openclaw gateway --port 18789 --bind lan
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PATH=/usr/bin:/usr/local/bin:/bin

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now openclaw.service
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
