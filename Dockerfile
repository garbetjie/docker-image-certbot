FROM alpine:3.8

ARG CERT_NAME=""
ARG DOMAINS=""
ARG EMAIL=""
ARG LOGS=false

ARG GCP_PROJECT=""
ARG GCP_SERVICE_ACCOUNT_FILE=""
ARG GCP_BUCKET_URN=""
ARG GCP_ENCRYPT_PASSWORD=""
ARG GCP_HTTPS_PROXY=""
ARG GCP_SSL_CERT_PREFIX=""
ARG GCP_SSL_CERT_SUFFIX="%Y%m"
ARG CERTBOT_VERSION="0.26.1"
ARG CERTBOT_DNS_PLUGIN_VERSION="0.26.1"

ENV CERTBOT_DNS_PLUGIN_VERSION="0.26.1" \
    CERTBOT_VERSION="0.26.1"

ENV CERT_NAME="${CERT_NAME}" \
    DOMAINS="${DOMAINS}" \
    EMAIL="${EMAIL}" \
    LOGS="${LOGS}" \
    GCP_SERVICE_ACCOUNT_FILE="${GCP_SERVICE_ACCOUNT_FILE}" \
    GCP_BUCKET_URN="${GCP_BUCKET_URN}" \
    GCP_ENCRYPT_PASSWORD="${GCP_ENCRYPT_PASSWORD}" \
    GCP_HTTPS_PROXY="${GCP_HTTPS_PROXY}" \
    GCP_SSL_CERT_PREFIX="${GCP_SSL_CERT_PREFIX}" \
    GCP_SSL_CERT_SUFFIX="${GCP_SSL_CERT_SUFFIX}"

RUN apk --no-cache add python2 py2-pip openssl jq && \
    apk --no-cache add --virtual .build-deps musl-dev gcc python2-dev libffi-dev openssl-dev && \
    pip install --no-cache-dir certbot==${CERTBOT_VERSION} certbot-dns-cloudflare==${CERTBOT_DNS_PLUGIN_VERSION} && \
    apk --no-cache del .build-deps

COPY init.sh /init
COPY deploy-hook.sh /opt/deploy-hook
COPY post-hook.sh /opt/post-hook

ENTRYPOINT ["/bin/sh"]
