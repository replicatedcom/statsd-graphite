#!/bin/sh

# The intention of this shell wrapper is to manage the PID file created by carbon-cache.
# If the file is left over, carbon-cache will refuse to start.
# The --nodaemon option allows the process to be managed by supervisord.
# The --pidfile overrides the default location which is on a mounted volume, which survives container restarts.

rm -f /tmp/carbon.pid
/usr/bin/carbon-cache start --nodaemon --pidfile=/tmp/carbon.pid --config=/opt/graphite/conf/carbon.conf
