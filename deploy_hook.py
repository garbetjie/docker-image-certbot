#!/usr/bin/env python

# The following environment variables are set by certbot:
# $RENEWED_LINEAGE - The path to the renewed SSL certificate.
# $RENEWED_DOMAINS - The domains in this certificate that were renewed/created.

from os import path, environ
import yaml
import traceback
import deploy_providers


# Load configuration file.
try:
    with open('/mnt/config.yml') as fp:
        config = yaml.load(fp)
except Exception as e:
    print "Unable to load YAML configuration: `%s`" % e.message
    print traceback.format_exc()
    exit(1)


# Find the certificate that matches the updated certificate name, and is enabled.
certificate = list(
    filter(
        lambda x: x['name'] == path.basename(environ.get('RENEWED_LINEAGE')),
        config['certificates']
    )
)

# We can only continue if a certificate was found.
if len(certificate) < 1:
    # TODO Add notification of no certificate found.
    print "No certificate configuration found for deployment."
    exit(0)
else:
    certificate = certificate[0]


# Run through providers, and build up a list of the ones that are enabled.

enabled_providers = []
for provider in ['google']:
    try:
        if certificate[provider]['enabled']:
            enabled_providers.append(provider)
    except KeyError:
        continue

if len(enabled_providers) < 1:
    # TODO Add notification of no certificate found.
    print "No enabled providers found for configuration. Not deploying anything."
    exit(0)


# Initialize the providers.
deploy_providers.init(environ.get('RENEWED_LINEAGE'))


# Deploy to providers.
try:
    if 'google' in enabled_providers:
        deploy_providers.google(certificate['google'])
finally:
    deploy_providers.cleanup()
