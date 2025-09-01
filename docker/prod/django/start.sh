#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Check if running in production environment
if [ -z "${DJANGO_SETTINGS_MODULE:-}" ]; then
    echo "Error: DJANGO_SETTINGS_MODULE environment variable not set!"
    exit 1
fi

# Verify working directory and manage.py
echo "Current working directory: $(pwd)"
echo "Contents:"
ls -la

if [ ! -f "manage.py" ]; then
    echo "Error: manage.py not found!"
    exit 1
fi

# Check if gunicorn is installed
if ! command -v gunicorn &> /dev/null; then
    echo "Error: gunicorn is not installed!"
    exit 1
fi

# Run database migrations with error handling
python manage.py migrate --no-input || {
    echo "Error: Database migration failed!"
    exit 1
}

# Collect static files with error handling
python manage.py collectstatic --no-input --clear || {
    echo "Error: Static files collection failed!"
    exit 1
}

# Load admin interface config
python manage.py loaddata admin_interface_config.json || {
    echo "Warning: Failed to load admin interface config"
}

# Create superuser if doesn't exist
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(email='admin@insuco.com').exists():
    User.objects.create_superuser('admin@insuco.com', 'admin123', 'admin', first_name='Mary', last_name='Jane')
    print('Superuser created')
"

# Start gunicorn
exec gunicorn --bind 0.0.0.0:8000 --workers 3 --timeout 120 --access-logfile - --error-logfile - config.wsgi:application