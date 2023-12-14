import sys
# In case of multi-instance graphite, uncomment and set appropriate name
# import os
# os.environ['GRAPHITE_SETTINGS_MODULE'] = 'graphite.local_settings'
sys.path.append('/usr/lib/python3/dist-packages')

from graphite.wsgi import application
