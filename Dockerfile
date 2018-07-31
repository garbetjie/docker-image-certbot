#FROM certbot/dns-google:v0.26.1
FROM alpine:3.8
RUN apk --no-cache add python2 py2-pip openssl && \
    apk --no-cache add --virtual .build-deps musl-dev gcc python2-dev libffi-dev openssl-dev && \
    pip install --no-cache-dir certbot certbot-dns-cloudflare && \
    apk --no-cache del .build-deps

#RUN apk update && apk add python2 py2-pip
#RUN apk add build-base
#RUN apk add python2-dev libffi-dev openssl-dev
#RUN pip install certbot certbot-dns-cloudflare
#RUN apk add openssl

ARG CERT_NAME="certname"
ARG DOMAINS="garbers.co.za,www.garbers.co.za"
ARG EMAIL="geoff@garbers.co.za"

ARG SERVICE_ACCOUNT_FILE="/mnt/service-account.json"
ARG LOGS="true"
ARG BUCKET_URN="ssl-certificates-a71689b5"
ARG BUCKET_ENCRYPT="pass"
ARG FORWARDING_RULE="dasds"
ARG SSL_CERT="ssl-cert-%Y%m"
ARG GOOGLE_HTTPS_PROXY="test-lb-target-proxy"
ARG GOOGLE_CERT_PREFIX="ssl-cert-"
ARG GOOGLE_CERT_SUFFIX="%Y%m"

ENV CERT_NAME="${CERT_NAME}" \
    SERVICE_ACCOUNT_FILE="${SERVICE_ACCOUNT_FILE}" \
    DOMAINS="${DOMAINS}" \
    EMAIL="${EMAIL}" \
    LOGS="${LOGS}" \
    BUCKET="${BUCKET}"

COPY init.sh /init

ENTRYPOINT ["/bin/sh"]
