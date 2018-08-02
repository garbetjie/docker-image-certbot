#!/usr/bin/env python
from subprocess import check_output as run
from os import path
from datetime import datetime
import json


class _Data:
    cert_name = None
    cert_dir = None
    cert_path = None
    tar_path = None

    gcloud_path = '/opt/google/bin/gcloud'
    gsutil_path = '/opt/google/bin/gsutil'


def init(cert_path):
    _Data.cert_path = cert_path
    _Data.cert_name = path.basename(cert_path)
    _Data.cert_dir = path.dirname(cert_path)
    _Data.tar_path = '/tmp/%s-%s.tar' % (_Data.cert_name, datetime.now().strftime('%Y%m'))

    run(['/bin/tar', '-chf', _Data.tar_path, '-C', _Data.cert_dir, _Data.cert_name])


def google(config):
    # Deployment provider not enabled.
    if 'enabled' not in config or not config['enabled']:
        return

    # Build environment to be used in commands.
    env = {}
    if 'project' in config:
        env['CLOUDSDK_CORE_PROJECT'] = config['project']

    # Enable the service account if a path to the file is provided.
    if 'service_account_file' in config:
        run([_Data.gcloud_path, 'auth', 'activate-service-account', '--key-file=%s' % config['service_account_file']])

    # Upload the certificates to a bucket if provided.
    if 'bucket_urn' in config:
        src_file = _Data.tar_path

        if 'encrypt_pass' in config:
            run(['/usr/bin/openssl', 'aes-256-cbc', '-e', '-k', config['encrypt_pass'], '-in', _Data.tar_path, '-out', _Data.tar_path + '.aes'])
            src_file = _Data.tar_path + '.aes'

        run([_Data.gsutil_path, '-q', 'cp', src_file, 'gs://%s' % config['bucket_urn']])

        if src_file != _Data.tar_path:
            run(['/bin/rm', '-f', src_file])

    # Create a new SSL certificate.
    if 'ssl_cert_prefix' in config and 'ssl_cert_suffix' in config:
        ssl_cert_name = datetime.now().strftime(str(config['ssl_cert_prefix']) + str(config['ssl_cert_suffix']))

        run([_Data.gcloud_path, 'compute', 'ssl-certificates', 'create', ssl_cert_name,
             '--certificate=%s/fullchain.pem' % _Data.cert_path,
             '--private-key=%s/privkey.pem' % _Data.cert_path],
            env=env)

        if 'target_proxy' in config:
            target_proxy = json.loads(
                run([_Data.gcloud_path, 'compute', 'target-https-proxies', 'describe', config['target_proxy'],
                     '--format', 'json'],
                    env=env)
            )

            # Remove any SSL certificates where the prefix is found at the beginning of the name.
            # Then, append the new certificate.
            attached_certificates = list(
                filter(
                    lambda attached_cert: not attached_cert.find(config['ssl_cert_prefix']) == 0,
                    map(lambda x: path.basename(x), target_proxy['sslCertificates'])
                )
            )
            attached_certificates.append(ssl_cert_name)

            # Update the target proxy.
            run([_Data.gcloud_path, 'compute', 'target-https-proxies', 'update', config['target_proxy'],
                 '--ssl-certificates=%s' % ",".join(attached_certificates)],
                env=env)


def cleanup():
    # Clean up tar files.
    run(['/bin/rm', '-f', _Data.tar_path])
