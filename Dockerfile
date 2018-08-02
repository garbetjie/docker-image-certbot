FROM alpine:3.8

ARG CERTBOT_VERSION="0.26.1"
ARG CERTBOT_DNS_PLUGIN_VERSION="0.26.1"
ARG GCLOUD_VERSION="210.0.0"
ARG COMPRESSED=false

ENV CERTBOT_DNS_PLUGIN_VERSION="${CERTBOT_VERSION}" \
    CERTBOT_VERSION="${CERTBOT_DNS_PLUGIN_VERSION}" \
    GCLOUD_VERSION="${GCLOUD_VERSION}"

RUN apk --no-cache add python2 py2-pip openssl && \
    apk --no-cache add --virtual .build-deps musl-dev gcc python2-dev libffi-dev openssl-dev wget && \
    pip install --no-cache-dir certbot==${CERTBOT_VERSION} certbot-dns-cloudflare==${CERTBOT_DNS_PLUGIN_VERSION} PyYAML && \
    mkdir /opt && \
    if [ "$COMPRESSED" = true ]; then \
        wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz -O /tmp/google-cloud-sdk.tar.gz; \
    else \
        wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz -O- | tar -xzf - -C /tmp && \
        mv /tmp/google-cloud-sdk /opt/google; \
    fi && \
    apk --no-cache del .build-deps

COPY init.py deploy_providers.py deploy_hook.py /opt/

ENTRYPOINT ["/opt/init.py"]
