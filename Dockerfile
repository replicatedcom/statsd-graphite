FROM debian:trixie-slim

# Things needed to install more things
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

# Setup nodejs repo
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
ENV NODE_MAJOR=16
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    nodejs \
    openssl \
    python3-dev \
    python3-cairo \
    supervisor \
    tzdata \
    \
    \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

ARG version=1.1.10
ARG statsd_version=0.10.1

ARG python_extra_flags="--single-version-externally-managed --root=/"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y graphite-web graphite-carbon uwsgi uwsgi-plugin-python3 python3-virtualenv git npm \
  && virtualenv /opt/graphite \
  && git clone https://github.com/statsd/statsd.git /opt/statsd \
  && cd /opt/statsd \
  && git checkout tags/v"${statsd_version}" \
  && npm install \
  && apt-get remove -y build-essential python3-pip libffi-dev git npm \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /root/.npm/_cacache

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
ADD conf/wsgi.py /opt/graphite/conf/wsgi.py
ADD conf/local_settings.py /usr/lib/python3/dist-packages/graphite/local_settings.py

# Set up required directories with permissions
RUN mkdir -p /var/log/supervisor /var/log/nginx /opt/graphite/storage /var/run/supervisord /var/run/nginx /var/run/uwsgi /crypto /var/lib/nginx /var/tmp /opt/graphite/storage/log/webapp
RUN chmod -R a+rwx /var/log/supervisor /var/log/nginx /opt/graphite/storage /var/run/supervisord /var/run/nginx /var/run/uwsgi /crypto /var/lib/nginx /var/tmp /opt/graphite/storage/log/webapp
RUN chmod a+x /carbon.sh

# Configure django DB
RUN mkdir -p /var/log/graphite/ \
  && PYTHONPATH=/opt/graphite/webapp django-admin migrate --pythonpath=/opt/graphite/webapp --noinput --settings=graphite.settings --run-syncdb

RUN chmod -R a+rwx \
  /opt/graphite/storage \
  # Fixes error Unable to write to plugin cache
  /usr/lib/python3/dist-packages/twisted/plugins

# Expose common ports
EXPOSE 2443
EXPOSE 8125/udp

# Enable users of this container to mount their volumes (optional)
VOLUME ["/opt/graphite/conf", "/opt/graphite/storage", "/opt/graphite/webapp/graphite/functions/custom", "/etc/nginx", "/opt/statsd/config", "/etc/logrotate.d", "/var/log", "/var/lib/redis", "/crypto", "/tmp", "/var/run/uwsgi", "/var/run/nginx", "/opt/graphite/lib/twisted/plugins", "/opt/graphite/lib/python3.7/site-packages/twisted/plugins"]

# Start supervisor by default
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf", "-l", "/var/log/supervisor/supervisord.log", "-j", "/var/run/supervisord/supervisord.pid"]
