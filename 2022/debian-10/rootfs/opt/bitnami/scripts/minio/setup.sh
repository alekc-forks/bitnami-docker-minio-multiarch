#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

# Load libraries
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libminio.sh

# Load MinIO environment
. /opt/bitnami/scripts/minio-env.sh

export MINIO_SERVER_PORT_NUMBER="$MINIO_API_PORT_NUMBER"
export MINIO_SERVER_SCHEME="$MINIO_SCHEME"
export MINIO_SERVER_ROOT_USER="${MINIO_ROOT_USER:-}"
export MINIO_SERVER_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-}"

# Load MinIO Client environment
. /opt/bitnami/scripts/minio-client-env.sh

# Validate settings in MINIO_* env vars.
minio_validate

# Keys regeneration
minio_regenerate_keys

if is_boolean_yes "$MINIO_SKIP_CLIENT"; then
    debug "Skipping MinIO client configuration..."
else
    if [[ "$MINIO_SERVER_SCHEME" = "https" ]]; then
        [[ ! -d "${MINIO_CLIENT_CONFIG_DIR}/certs/CAs" ]] && mkdir -p "${MINIO_CLIENT_CONFIG_DIR}/certs/CAs"
        cp "${MINIO_CERTS_DIR}/CAs/public.crt" "${MINIO_CLIENT_CONFIG_DIR}/certs/CAs/"
    fi
    # Start MinIO server in background
    minio_start_bg
    # Ensure MinIO Client is stopped when this script ends.
    trap "minio_stop" EXIT
    if is_boolean_yes "$MINIO_DISTRIBUTED_MODE_ENABLED"; then
        if is_distributed_ellipses_syntax; then
            read -r -a drives <<< "$(minio_distributed_drives)"
            minio_client_configure_local "/${drives[0]}/.minio.sys/config/config.json"
        else
            minio_client_configure_local "${MINIO_DATA_DIR}/.minio.sys/config/config.json"
        fi
        # Wait for other clients (distribute mode)
        sleep 5
    else
        minio_client_configure_local "${MINIO_DATA_DIR}/.minio.sys/config/config.json"
    fi
    # Create default buckets
    minio_create_default_buckets
fi
