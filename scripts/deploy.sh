#!/bin/bash
# deploy.sh - Script de déploiement pour Sycosur
# Ce script compresse le projet, le transfère sur un serveur distant via SSH,

set -e

# Configuration des variables de connexion SSH
REMOTE_USER="ubuntu"
REMOTE_HOST="ns526301.ip-149-56-16.net"
REMOTE_PORT="49160"
REMOTE_APP_DIR="/var/www/public_html"
REMOTE_TMP_DIR="/tmp"
BRANCH="main"
PROJECT_NAME="sycosur"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
LOG_FILE="deploy_${TIMESTAMP}.log"

# Fonction pour écrire dans le log
log_message() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $1" | tee -a "$LOG_FILE"
}

log_message "🚀 Démarrage du processus de déploiement..."

# Vérification que le script est exécuté depuis la racine du projet
if [ ! -f "prod.yml" ]; then
    log_message "❌ Erreur: Ce script doit être exécuté depuis la racine du projet Sycosur"
    log_message "   Utilisez: ./scripts/deploy.sh"
    exit 1
fi

# Vérification de la branche actuelle
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    log_message "⚠️ Attention: Vous n'êtes pas sur la branche $BRANCH (branche actuelle: $CURRENT_BRANCH)"
    read -p "Voulez-vous continuer quand même? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_message "❌ Déploiement annulé"
        exit 1
    fi
fi

# Création de l'archive du projet
log_message "📦 Création de l'archive du projet..."
if ! git archive --format tar --prefix="${PROJECT_NAME}/" "$BRANCH" | gzip > "$ARCHIVE_NAME"; then
    log_message "Error: Échec de la création de l'archive du projet"
    exit 1
fi

log_message "Archive créée: $ARCHIVE_NAME"

log_message "📤 Envoi du projet vers le serveur..."
if ! scp -P $REMOTE_PORT "$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_TMP_DIR/$ARCHIVE_NAME"; then
    log_message "Error: Échec de l'envoi du projet"
    exit 1
fi

# Exécution des commandes sur le serveur avec port SSH spécifique
log_message "🛠️ Construction et déploiement sur le serveur..."
ssh -o StrictHostKeyChecking=no -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" << ENDSSH
    set -e
    echo "Vérification et création du répertoire d'application si nécessaire..."
    if [ ! -d "$REMOTE_APP_DIR" ]; then
        echo "Le répertoire $REMOTE_APP_DIR n'existe pas, création en cours..."
        sudo mkdir -p $REMOTE_APP_DIR || { echo "Erreur: Impossible de créer le répertoire $REMOTE_APP_DIR"; exit 1; }
    fi
    
    # S'assurer que l'utilisateur a les permissions nécessaires sur le répertoire
    sudo chown -R \$(whoami):\$(whoami) $REMOTE_APP_DIR || { echo "Erreur: Impossible de modifier les permissions du répertoire $REMOTE_APP_DIR"; exit 1; }
    sudo chmod 755 $REMOTE_APP_DIR || { echo "Erreur: Impossible de modifier les permissions du répertoire $REMOTE_APP_DIR"; exit 1; }
    
    # Créer explicitement les sous-répertoires importants avec les bonnes permissions
    echo "Création des sous-répertoires importants..."
    for dir in backend client docker docs scripts; do
        sudo mkdir -p $REMOTE_APP_DIR/$dir || { echo "Erreur: Impossible de créer le sous-répertoire $dir"; exit 1; }
        sudo chown \$(whoami):\$(whoami) $REMOTE_APP_DIR/$dir || { echo "Erreur: Impossible de modifier les permissions du sous-répertoire $dir"; exit 1; }
        sudo chmod 755 $REMOTE_APP_DIR/$dir || { echo "Erreur: Impossible de modifier les permissions du sous-répertoire $dir"; exit 1; }
    done
    
    # Créer explicitement les sous-répertoires de docker
    for subdir in local prod; do
        sudo mkdir -p $REMOTE_APP_DIR/docker/$subdir || { echo "Erreur: Impossible de créer le sous-répertoire docker/$subdir"; exit 1; }
        sudo chown \$(whoami):\$(whoami) $REMOTE_APP_DIR/docker/$subdir || { echo "Erreur: Impossible de modifier les permissions du sous-répertoire docker/$subdir"; exit 1; }
        sudo chmod 755 $REMOTE_APP_DIR/docker/$subdir || { echo "Erreur: Impossible de modifier les permissions du sous-répertoire docker/$subdir"; exit 1; }
    done

    echo "Extraction des fichiers du projet..."
    # Supprimer le contenu du répertoire cible
    sudo rm -rf $REMOTE_APP_DIR/* || { echo "Erreur: Impossible de nettoyer le répertoire $REMOTE_APP_DIR"; exit 1; }
    
    # Extraire l'archive avec gestion d'erreur détaillée
    echo "Extraction de l'archive $REMOTE_TMP_DIR/$ARCHIVE_NAME vers $REMOTE_APP_DIR..."
    if ! sudo tar -xzvf $REMOTE_TMP_DIR/$ARCHIVE_NAME -C $REMOTE_APP_DIR --strip-components=1; then
        echo "Erreur: L'extraction de l'archive a échoué. Vérifiez les permissions et l'intégrité de l'archive."
        exit 1
    fi
    echo "Extraction terminée avec succès."

    echo "Configuration des permissions..."
    echo "Configuration des permissions pour les fichiers..."
    if ! sudo find $REMOTE_APP_DIR -type f -exec chmod 644 {} \; ; then
        echo "Attention: Certaines permissions de fichiers n'ont pas pu être configurées"
    fi
    
    echo "Configuration des permissions pour les répertoires..."
    if ! sudo find $REMOTE_APP_DIR -type d -exec chmod 755 {} \; ; then
        echo "Attention: Certaines permissions de répertoires n'ont pas pu être configurées"
    fi
    
    echo "Configuration des permissions pour les scripts shell..."
    if ! sudo find $REMOTE_APP_DIR -name "*.sh" -exec chmod 755 {} \; ; then
        echo "Attention: Certaines permissions de scripts n'ont pas pu être configurées"
    fi
    
    # S'assurer que l'utilisateur a les permissions nécessaires
    echo "Attribution de la propriété des fichiers à l'utilisateur courant..."
    if ! sudo chown -R $(whoami):$(whoami) $REMOTE_APP_DIR; then
        echo "Attention: La propriété de certains fichiers n'a pas pu être modifiée"
    fi

    echo "Configuration des permissions terminée."

    echo "Nettoyage..."
    sudo rm -f $REMOTE_TMP_DIR/$ARCHIVE_NAME || echo "Attention: Impossible de supprimer l'archive temporaire"
ENDSSH

log_message "✅ Déploiement terminé avec succès!"

rm -f "$ARCHIVE_NAME"
log_message "🧹 Fichiers temporaires supprimés"

