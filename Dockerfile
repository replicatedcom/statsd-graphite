FROM alpine:3.6

# Borrowed from https://github.com/CastawayLabs/graphite-statsd
# Initial work from https://github.com/hopsoft/docker-graphite-statsd
# More from https://github.com/yesoreyeram/graphite-setup

# Install dependencies
RUN apk add --update --no-cache \
  nginx \
  supervisor \
  openssl \
  nodejs \
  tzdata \
  libffi \
  gtk+ \
  gcc \
  py-pip \
  uwsgi \
  uwsgi-python \
 && rm -rf /var/cache/apk/*

RUN apk add --update --no-cache linux-headers musl-dev python-dev libffi-dev git \
  && pip install -r https://raw.githubusercontent.com/graphite-project/whisper/1.0.2/requirements.txt \
  && pip install -r https://raw.githubusercontent.com/graphite-project/carbon/1.0.2/requirements.txt \
  && pip install -r https://raw.githubusercontent.com/graphite-project/graphite-web/1.0.2/requirements.txt \
  && pip install https://github.com/graphite-project/carbon/tarball/1.0.2 \
  && pip install https://github.com/graphite-project/graphite-web/tarball/1.0.2 \
  && git clone -b v0.8.0 https://github.com/etsy/statsd.git /opt/statsd \
  && apk del linux-headers musl-dev python-dev libffi-dev git \
  && rm -rf /var/cache/apk/*

# Configure nginx site
RUN rm -rf /etc/nginx/sites-enabled/*

ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/graphite.ini /etc/uwsgi/apps-enabled/conf/graphite.ini
ADD conf/graphite.conf /etc/nginx/sites-enabled/graphite
ADD conf/supervisord.conf /etc/supervisord.conf

# Graphite/statsd/carbon config files
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
RUN mkdir -p /tmp/supervisord /var/log/nginx /var/log/graphite /var/log/carbon /var/log/uwsgi /opt/graphite/storage /var/run/nginx /crypto
RUN chmod -R a+rwx /tmp/supervisord /var/log/nginx /var/log/graphite /var/log/carbon /var/log/uwsgi /opt/graphite/storage /var/run/nginx /crypto

# Configure django DB
RUN PYTHONPATH=/opt/graphite/webapp python /usr/bin/django-admin.py migrate --settings=graphite.settings --run-syncdb

# Expose common ports
EXPOSE 2443
EXPOSE 8125/udp

# Enable users of this container to mount their volumes (optional)
VOLUME /var/log /opt/graphite/storage /opt/graphite/conf /crypto

# Start supervisor by default
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf", "-l", "/tmp/supervisord/supervisord.log", "-j", "/tmp/supervisord/supervisord.pid"]
