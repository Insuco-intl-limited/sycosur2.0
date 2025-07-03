build:
	docker compose -f local.yml up --build -d --remove-orphans

up:
	docker compose -f local.yml up -d

down:
	docker compose -f local.yml down

down-v:
	docker compose -f local.yml down -v

show-logs:
	docker compose -f local.yml logs

show-logs-api:
	docker compose -f local.yml logs api

makemigrations:
	docker compose -f local.yml run --rm api python manage.py makemigrations

migrate:
	docker compose -f local.yml run --rm api python manage.py migrate

collectstatic:
	docker compose -f local.yml run --rm api python manage.py collectstatic --no-input --clear

superuser:
	docker compose -f local.yml run --rm api python manage.py createsuperuser

dump_admin:
	docker compose -f local.yml run --rm api python manage.py dumpdata admin_interface --indent 2 > ./backend/admin_interface_config.json

db-volume:
	docker volume inspect sycosur_postgres_data

mailpit-volume:
	docker volume inspect sycosur_mailpit_data

sycosur-db:
	docker compose -f local.yml exec postgres psql --username=admin --dbname=sycosur