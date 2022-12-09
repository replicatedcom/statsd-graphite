FROM registry.replicated.com/library/statsd-graphite:1.1.8-20211119

# Install dependencies
RUN apt-get update && apt-get upgrade -y \
  && apt-get purge dpkg-dev -y \
  && apt-get purge git -y \
  && apt-get clean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*
