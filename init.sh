#!/bin/sh
set -x
if [ "${CERT_NAME}" = "" ]; then echo '$CERT_NAME is required' && exit 1; fi
if [ "${DOMAINS}" = "" ]; then echo '$DOMAINS is required' && exit 1; fi
if [ "${EMAIL}" = "" ]; then echo '$EMAIL is required' && exit 1; fi

DRY_RUN=
TEST_CERT=
COMMAND=

# Parse arguments.
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN="--dry-run"
            ;;
        --test-cert)
            TEST_CERT="--test-cert"
            ;;
        -*)
            echo "Unknown argument \`${1}\`"
            exit 1
            ;;
        *)
            if [ "$COMMAND" != "" ]; then echo "A command has already been provided, and cannot be provided again (${COMMAND})."; exit 1; fi
            COMMAND="$1"
            ;;
    esac
    shift
done

# Ensure we have a command.
if [ -z $COMMAND ]; then echo "A command is required."; exit 1; fi

exec certbot "$COMMAND" -n --agree-tos \
       -m "${EMAIL}" \
       -d "${DOMAINS}" \
       ${TEST_CERT} \
       ${DRY_RUN} \
       --cert-name "${CERT_NAME}" \
       --dns-cloudflare --dns-cloudflare-credentials /mnt/cloudflare.ini \
       --deploy-hook /mnt/deploy-hook.sh \
       --post-hook /mnt/post-hook.sh
