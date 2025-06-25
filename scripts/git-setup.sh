#!/bin/bash
echo "🚀 Configuration initiale du projet..."

# Initialiser submodules si présents
if [ -f ../.gitmodules ]; then
    git submodule update --init --recursive
fi

# Installer hooks Git
if [ -f pre-commit ]; then
    cp pre-commit ../.git/hooks/
    chmod +x ../.git/hooks/pre-commit
    echo "📎 Hook pre-commit installé"
fi

# Configuration Git
git config core.autocrlf false
git config pull.rebase true

# Créer .env s'il n'existe pas
if [ ! -f ../.env ]; then
    cp ../.env.example ../.env
    echo "📝 Fichier .env créé - personnalisez-le"
fi

echo "✅ Configuration terminée!"
