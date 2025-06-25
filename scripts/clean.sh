#!/bin/bash
echo "🧹 Nettoyage du système..."

cd ..
docker-compose down
docker image prune -f
docker volume prune -f
docker system prune -f

echo "✅ Nettoyage terminé"
