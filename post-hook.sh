#!/bin/sh

# If we're not keeping the logs, then remove them here.
if [ "$LOGS" = false ]; then rm -rf /var/log/letsencrypt/*; fi
