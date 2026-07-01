#!/bin/bash
# Gracefully stop app processes; ignore errors if pm2 isn't running yet (first deploy).
pm2 stop frontdesk frontdesk-mcp 2>/dev/null || true
