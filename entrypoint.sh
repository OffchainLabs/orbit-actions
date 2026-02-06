#!/bin/bash
# Source .env if mounted, then delegate to router
[[ -f /app/.env ]] && set -a && source /app/.env && set +a
exec /app/bin/router "$@"
