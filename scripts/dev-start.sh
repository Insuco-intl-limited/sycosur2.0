#!/bin/bash
echo "🚀 Démarrage environnement de développement..."

# Vérifier Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker n'est pas démarré"
    exit 1
fi

# Copier .env si nécessaire
if [ ! -f ../.env ]; then
    cp ../.env.example ../.env
    echo "📝 Fichier .env créé"
fi

# Démarrer les services
cd ..
docker-compose up -d --build

echo "⏳ Attente du démarrage..."
sleep 15

echo "🏥 État des services:"
docker-compose ps

echo ""
echo "🌍 Services disponibles:"
echo "   Frontend:     http://localhost:3000"
echo "   Backend API:  http://localhost:8000"
echo "   Nginx:        http://localhost"
echo ""
