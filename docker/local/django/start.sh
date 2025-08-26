#!/bin/bash

set -o errexit

set -o pipefail

set -o nounset

# Vérifier que nous sommes dans le bon répertoire
echo "Current working directory: $(pwd)"
echo "Contents:"
ls -la

# Vérifier que manage.py existe
if [ ! -f "manage.py" ]; then
    echo "Error: manage.py not found!"
    exit 1
fi

python manage.py makemigrations
python manage.py migrate --no-input
python manage.py collectstatic --no-input

# load admin interface config
python manage.py loaddata admin_interface_config.json

# Créer un superuser si il n'existe pas
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(email='admin@insuco.com').exists():
    User.objects.create_superuser('admin@insuco.com', 'admin123', 'admin', first_name='Mary', last_name='Jane')
    print('Superuser created')
"
exec python manage.py runserver 0.0.0.0:8001