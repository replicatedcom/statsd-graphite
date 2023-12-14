SECRET_KEY = '$(date +%s | sha256sum | base64 | head -c 64)'
ALLOWED_HOSTS = ['*']
GRAPHITE_ROOT = '/opt/graphite'
LOG_DIR = '/opt/graphite/storage/log/webapp'
