#!/bin/bash
set -e
cd /opt/frontdesk
pm2 start ecosystem.config.cjs
pm2 startup systemd -u root --hp /root
pm2 save
