FROM debian:buster-slim

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
    npm \
    python3-dev \
    python3-cairo \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

ARG version=1.1.7
ARG statsd_version=0.9.0

RUN apt-get update && apt-get install -y --no-install-recommends gcc python3-pip python3-setuptools libffi-dev git \
  && pip3 install wheel \
  && pip3 install uwsgi \
  && pip3 install virtualenv==16.7.10 \
  && virtualenv /opt/graphite \
  && . /opt/graphite/bin/activate \
  && git clone -b ${version} --depth 1 https://github.com/graphite-project/whisper.git /usr/local/src/whisper \
  && cd /usr/local/src/whisper \
  && python3 ./setup.py install \
  && git clone -b ${version} --depth 1 https://github.com/graphite-project/carbon.git /usr/local/src/carbon \
  && cd /usr/local/src/carbon \
  && pip3 install -r requirements.txt \
  && python3 ./setup.py install \
  && git clone -b ${version} --depth 1 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web \
  && cd /usr/local/src/graphite-web \
  && pip3 install -r requirements.txt \
  && python3 ./setup.py install \
  && git clone https://github.com/statsd/statsd.git /opt/statsd \
  && cd /opt/statsd \
  && git checkout tags/v"${statsd_version}" \
  && npm install \
  && apt-get remove -y gcc python3-pip python3-setuptools libffi-dev git \
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
ADD conf/statsd/config.js /opt/statsd/config.js
ADD conf/graphite/ /opt/graphite/conf/
ADD conf/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
RUN mv /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/wsgi.py

# Set up required directories with permissions
RUN mkdir -p /var/log/supervisor /var/log/nginx /opt/graphite/storage /var/run/supervisord /var/run/nginx /var/run/uwsgi /crypto /var/lib/nginx /var/tmp
RUN chmod -R a+rwx /var/log/supervisor /var/log/nginx /opt/graphite/storage /var/run/supervisord /var/run/nginx /var/run/uwsgi /crypto /var/lib/nginx /var/tmp
RUN chmod a+x /carbon.sh

# Configure django DB
RUN mkdir -p /var/log/graphite/ \
  && PYTHONPATH=/opt/graphite/webapp /opt/graphite/bin/django-admin.py collectstatic --noinput --settings=graphite.settings \
  && PYTHONPATH=/opt/graphite/webapp /opt/graphite/bin/django-admin.py migrate --noinput --settings=graphite.settings --run-syncdb

RUN chmod -R a+rwx /opt/graphite/storage

# Expose common ports
EXPOSE 2443
EXPOSE 8125/udp

# Enable users of this container to mount their volumes (optional)
VOLUME /var/log /opt/graphite/storage /opt/graphite/conf /crypto

# Start supervisor by default
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf", "-l", "/var/log/supervisor/supervisord.log", "-j", "/var/run/supervisord/supervisord.pid"]
