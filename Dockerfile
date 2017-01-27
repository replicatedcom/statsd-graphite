FROM alpine:3.3
MAINTAINER Matej Kramny <matejkramny@gmail.com>

# Borrowed from https://github.com/CastawayLabs/graphite-statsd
# Initial work from https://github.com/hopsoft/docker-graphite-statsd

# Install dependencies
RUN apk add --update \
  nginx \
  supervisor \
  openssl \
  expect \
  nodejs \
  tzdata \
  py-cairo \
  py-pip && \
 rm -rf /var/cache/apk/*

RUN apk add --update gcc python-dev musl-dev && \
  pip install twisted==11.1.0 && \
  apk del gcc python-dev musl-dev && \
  rm -rf /var/cache/apk/*

# Configure log dirs (might be useless)
RUN mkdir -p /var/log/nginx
RUN mkdir -p /var/log/carbon
RUN mkdir -p /var/log/graphite

# python-memcached==1.53 \
RUN pip install \
  django==1.3 \
  django-tagging==0.3.1 \
  whisper==0.9.12 \
  flup==1.0.2

# Install Graphite/Whisper/Carbon
RUN apk add --update git && \
  git clone -b 0.9.12 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web && \
  cd /usr/local/src/graphite-web && \
  python ./setup.py install && \
  git clone -b 0.9.12 https://github.com/graphite-project/whisper.git /usr/local/src/whisper && \
  cd /usr/local/src/whisper && \
  python ./setup.py install && \
  git clone -b 0.9.12 https://github.com/graphite-project/carbon.git /usr/local/src/carbon && \
  cd /usr/local/src/carbon && \
  python ./setup.py install && \
  git clone -b v0.7.2 https://github.com/etsy/statsd.git /opt/statsd && \
  apk del git && \
  rm -rf /var/cache/apk/*

# Configure nginx site
RUN rm -rf /etc/nginx/sites-enabled/*

ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/graphite-site.conf /etc/nginx/sites-enabled/graphite
ADD conf/graphite_syncdb.sh /opt/graphite_syncdb
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

# Configure django DB
RUN chmod 775 /opt/graphite_syncdb
RUN /opt/graphite_syncdb

# Expose common ports
#EXPOSE 80
EXPOSE 443
#EXPOSE 2003
EXPOSE 8125/udp

# Enable users of this container to mount their volumes (optional)
VOLUME /var/log
VOLUME /opt/graphite/storage
VOLUME /opt/graphite/conf

# Start supervisor by default
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
