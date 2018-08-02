#!/usr/bin/env python

import os.path as path
import yaml
import traceback
import argparse
from subprocess import check_call as run

parser = argparse.ArgumentParser()
sub_parsers = parser.add_subparsers(dest='command')

# Add `certonly` sub parser.
parser_certonly = sub_parsers.add_parser('certonly')
parser_certonly.add_argument('--name', required=True, help='The name of the certificate (as defined in config.yml) to acquire or renew.')
parser_certonly.add_argument('--test-cert', action='store_true', help='Obtain a test certificate from a staging server.')
parser_certonly.add_argument('--dry-run', action='store_true', help='Test "renew" or "certonly" without saving any certificates to disk.')

# Add `renew` sub parser.
parser_renew = sub_parsers.add_parser('renew')

# Parse arguments.
args = parser.parse_args()


# Load configuration file.
try:
    with open('/mnt/config.yml') as fp:
        config = yaml.load(fp)
except Exception as e:
    print "Unable to load YAML configuration: `%s`" % e.message
    print traceback.format_exc()
    exit(1)

# Find the certificate that matches the updated certificate name, and is enabled.
cert = list(filter(lambda x: x['name'] == args.name, config['certificates']))


# We can only continue if a certificate was found.
if len(cert) < 1:
    print "No configuration found for certificate `%s`." % args.name
    exit(0)
else:
    cert = cert[0]


# Determine the email address to use.
if 'email' in cert:
    email = str(cert['email'])
elif 'email' in config:
    email = str(config['email'])
else:
    print "No email defined in any configuration. An email address is required."
    exit(1)


# Before we request the certificates, ensure that we have the cloud provider SDKs available.
# If there is no /opt/{provider} directory, then we can make the assumption that we're using the compressed version,
# and so need to uncompress it.
if not path.isdir('/opt/google'):
    run(['/bin/tar', '-xzf', '/tmp/google-cloud-sdk.tar.gz'])


# Build the initial command.
cmd = ['/usr/bin/certbot', args.command,
       '-n', '--agree-tos',
       '-m', email,
       '--dns-cloudflare', '--dns-cloudflare-credentials', '/mnt/cloudflare.ini',
       '--deploy-hook', '/opt/deploy-hook',
       '--preferred-challenges', 'dns-01,http-01']


# Add the staging flag.
if args.test_cert:
    cmd.append('--test-cert')


# Add the dry run flag.
if args.dry_run:
    cmd.append('--dry-run')


# Add additional parameters if we're running the certonly command.
if args.command == 'certonly':
    cmd.extend(['--expand', '--cert-name', cert['name']])

    for domain in cert['domains']:
        cmd.extend(['-d', domain])


# Run the command.
run(cmd)
