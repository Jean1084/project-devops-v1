#!/bin/bash

WORKSPACE_DIR="/home/vagrant/workspace"
WORKSPACE_PROJECT="/home/vagrant/workspace/project-devops-v1"
SSH_KEY_PATH="/home/vagrant/.ssh/id_rsa"
WORKSPACE_DOCKER="/home/vagrant/workspace/project-devops-v1/simple_api"
source .env

echo "Starting SSH agent..."
eval "$(ssh-agent -s)" || { echo "Failed to start ssh-agent"; exit 1; }
ssh-add "$SSH_KEY_PATH"
sleep 2

echo "Creating workspace folder..."
mkdir -p "$WORKSPACE_DIR"
chown vagrant:vagrant "$WORKSPACE_DIR"
chmod 700 "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

if [ ! -d "$WORKSPACE_PROJECT/.git" ]; then
    echo "Cloning project into '$WORKSPACE_PROJECT'..."
    sudo -u vagrant -H bash -c "GIT_SSH_COMMAND='ssh -i $SSH_KEY_PATH -o StrictHostKeyChecking=accept-new' git clone git@github.com:Jean1084/project-devops-v1.git $WORKSPACE_PROJECT"
    chown -R vagrant:vagrant "$WORKSPACE_PROJECT"
    chmod -R 700 "$WORKSPACE_PROJECT"
    echo "Git clone done!"
else
    echo "Project already exists, pulling latest changes..."
    cd "$WORKSPACE_PROJECT"
    sudo -u vagrant -H git pull origin main
fi

# Charger les variables d'environnement
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Erreur : Fichier .env introuvable !"
    exit 1
fi

echo "Vérification de Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "Docker n'est pas en cours d'exécution ou l'utilisateur n'a pas les permissions"
    exit 1
fi

# Nettoyage des anciennes images inutiles
echo "Suppression des anciennes images..."
docker rmi -f simple-api-jean || true
docker image prune -f -a

# Construction de l’image Docker
cd "$WORKSPACE_DOCKER" || exit
echo "Construction de l'image Docker..."
docker build --no-cache -t simple-api-jean .

# Connexion à Docker Hub
echo "Connexion à Docker Hub..."
echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

# Vérification de l’authentification
if [ $? -ne 0 ]; then
    echo "Échec de la connexion à Docker Hub"
    exit 1
fi

# Taguer et pousser l'image Docker
echo "Préparation de l’image..."
docker tag simple-api-jean "$DOCKER_USER/simple-api-jean:latest"

echo "Envoi de l'image vers Docker Hub..."
docker push "$DOCKER_USER/simple-api-jean:latest" &> /dev/null &  # Exécution en arrière-plan
disown
echo "L'envoi de l'image est en cours en arrière-plan..."