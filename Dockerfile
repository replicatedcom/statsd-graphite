FROM debian:stretch-slim

# Borrowed from https://github.com/CastawayLabs/graphite-statsd
# Initial work from https://github.com/hopsoft/docker-graphite-statsd
# More from https://github.com/yesoreyeram/graphite-setup

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    nginx \
    supervisor \
    openssl \
    tzdata \
    nodejs \
    libpython2.7 \
    libcairo2 \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
  && apt-get install -y --no-install-recommends \
    nodejs \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends gcc python-pip python-dev python-setuptools libffi-dev git \
  && pip install wheel \
  && pip install uwsgi==2.0.18 \
  && pip install -r https://raw.githubusercontent.com/graphite-project/whisper/1.0.2/requirements.txt \
  && pip install -r https://raw.githubusercontent.com/graphite-project/carbon/1.0.2/requirements.txt \
  && pip install whitenoise==3.3.1 \
  && pip install -r https://raw.githubusercontent.com/graphite-project/graphite-web/1.0.2/requirements.txt \
  && pip install https://github.com/graphite-project/carbon/tarball/1.0.2 \
  && pip install https://github.com/graphite-project/graphite-web/tarball/1.0.2 \
  && git clone https://github.com/etsy/statsd.git /opt/statsd && (cd /opt/statsd && git checkout 8d5363cb109cc6363661a1d5813e0b96787c4411) \
  && apt-get remove -y gcc python-pip python-dev python-setuptools libffi-dev git \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

# Configure nginx site
RUN rm -rf /etc/nginx/sites-enabled/*

ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/graphite.ini /etc/uwsgi/apps-enabled/conf/graphite.ini
ADD conf/graphite.conf /etc/nginx/sites-enabled/graphite
ADD conf/supervisord.conf /etc/supervisord.conf

# Graphite/statsd/carbon config files
ADD conf/carbon.sh /carbon.sh
ADD conf/statsd-config.js /opt/statsd/config.js
ADD conf/aggregation-rules.conf /opt/graphite/conf/aggragation-rules.conf
ADD conf/blacklist.conf /opt/graphite/conf/blacklist.conf
ADD conf/carbon.amqp.conf /opt/graphite/conf/carbon.amqp.conf
ADD conf/carbon.conf /opt/graphite/conf/carbon.conf
ADD conf/relay-rules.conf /opt/graphite/conf/relay-rules.conf
ADD conf/rewrite-rules.conf /opt/graphite/conf/rewrite-rules.conf
ADD conf/storage-aggregation.conf /opt/graphite/conf/storage-aggregation.conf
ADD conf/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
ADD conf/whitelist.conf /opt/graphite/conf/whitelist.conf
ADD conf/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
RUN mv /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/wsgi.py

# Set up required directories with permissions
RUN mkdir -p /var/log/supervisor /var/log/nginx /opt/graphite/storage /var/run/supervisord /var/run/nginx /var/run/uwsgi /crypto /var/lib/nginx /var/tmp
RUN chmod -R a+rwx /var/log/supervisor /var/log/nginx /opt/graphite/storage /var/run/supervisord /var/run/nginx /var/run/uwsgi /crypto /var/lib/nginx /var/tmp
RUN chmod a+x /carbon.sh

# Configure django DB
RUN PYTHONPATH=/opt/graphite/webapp python /usr/local/bin/django-admin.py migrate --settings=graphite.settings --run-syncdb

RUN chmod -R a+rwx /opt/graphite/storage

# Expose common ports
EXPOSE 2443
EXPOSE 8125/udp

# Enable users of this container to mount their volumes (optional)
VOLUME /var/log /opt/graphite/storage /opt/graphite/conf /crypto

# Start supervisor by default
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf", "-l", "/var/log/supervisor/supervisord.log", "-j", "/var/run/supervisord/supervisord.pid"]
