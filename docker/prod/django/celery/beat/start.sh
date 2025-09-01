#!/bin/bash

set -o errexit
set -o nounset

# Remove stale pidfile if it exists
rm -f './celerybeat.pid'

# Run celery beat in production mode
exec celery -A config.celery_app beat \
    --loglevel=INFO \
    --pidfile=./celerybeat.pid \
    --scheduler=django_celery_beat.schedulers:DatabaseScheduler