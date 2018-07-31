#!/bin/sh
set -ex

# The following environment variables are set by certbot:
# $RENEWED_LINEAGE - The path to the renewed SSL certificate.
# $RENEWED_DOMAINS - The domains in this certificate that were renewed/created.


# Activate the service account if provided.
if [ "$GCP_SERVICE_ACCOUNT_FILE" != "" ]; then
    if [ ! -f "$GCP_SERVICE_ACCOUNT_FILE" ]; then echo "Service account file \`${GCP_SERVICE_ACCOUNT_FILE}\` doesn't exist."; exit 1; fi

    gcloud auth activate-service-account --key-file="$GCP_SERVICE_ACCOUNT_FILE"
fi


# Upload to a cloud storage bucket. Encrypt it before uploading.
if [ "$GCP_BUCKET_URN" != "" ]; then
    tar_file="/tmp/${CERT_NAME}-$(date +'%Y%m').tar"
    upload_file="$tar_file"

    # Create tar archive.
    tar -chf "$tar_file" -C $(dirname $RENEWED_LINEAGE) $(basename $RENEWED_LINEAGE)

    # Encrypt the archive file.
    if [ "$GCP_ENCRYPT_PASSWORD" != "" ]; then
        openssl aes-256-cbc -e -k "$GCP_ENCRYPT_PASSWORD" -in "$tar_file" -out "${tar_file}.encrypted"
        upload_file="${tar_file}.encrypted"
    fi

    gsutil -q cp "$upload_file" "gs://${GCP_BUCKET_URN}"
    rm -f "$tar_file" "$upload_file"
fi

# If there is an SSL certificate name defined, create a new certificate after date formatting the name.
if [ "$GCP_SSL_CERT_PREFIX" != "" ] && [ "$GCP_SSL_CERT_SUFFIX" != "" ]; then
    google_cert_name="$(date +"${GCP_SSL_CERT_PREFIX}")$(date +"${GCP_SSL_CERT_SUFFIX}")"

    gcloud compute ssl-certificates create "$google_cert_name" \
        --certificate="${RENEWED_LINEAGE}/fullchain.pem" \
        --private-key="${RENEWED_LINEAGE}/privkey.pem"

    # Update the target HTTPS proxy if provided.
    if [ "$GCP_HTTPS_PROXY" != "" ]; then
        attached_certs="$(gcloud compute target-https-proxies describe "$GCP_HTTPS_PROXY" --format json | jq '(.sslCertificates[] | split("/"))[-1]' - -r)"
        replaced_certs="${google_cert_name}"

        for attached_cert in $attached_certs; do
            if ! echo "$attached_cert" | grep -q "$GCP_SSL_CERT_PREFIX"; then
                replaced_certs="${replaced_certs},${attached_cert}"
            fi
        done

        gcloud compute target-https-proxies update "$GCP_HTTPS_PROXY" --ssl-certificates="$replaced_certs"
    fi
fi
