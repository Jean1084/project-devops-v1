#!/bin/bash
source .env

# Charger les variables d'environnement
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Erreur : Fichier .env introuvable !"
    exit 1
fi

WORKSPACE_PROJECT="/home/vagrant/workspace"
SSH_KEY_PATH="/home/vagrant/.ssh/id_rsa"
WORKSPACE_DOCKER="/home/vagrant/workspace/simple_api"

echo "Starting SSH agent..."
eval "$(ssh-agent -s)" || { echo "Failed to start ssh-agent"; exit 1; }
ssh-add "$SSH_KEY_PATH"
sleep 2

echo "Creating workspace folder..."
mkdir -p "$WORKSPACE_PROJECT"
chown vagrant:vagrant "$WORKSPACE_PROJECT"
chmod 700 "$WORKSPACE_PROJECT"
cd "$WORKSPACE_PROJECT"

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

echo "Démarrage de Docker..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Vérification de Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "Docker n'est pas en cours d'exécution ou l'utilisateur n'a pas les permissions"
    exit 1
fi

# Nettoyage des anciennes images inutiles
echo "Suppression des anciennes images..."
docker rmi -f simple-api-jean || true
docker rmi -f php-apache-jean || true
docker image prune -f -a

# Construction de l’image Docker simple-api-jean
cd "$WORKSPACE_DOCKER" || exit
echo "Construction de l'image Docker - simple-api-jean..."
docker build --no-cache -t simple-api-jean .
sleep 2

# Creation docker network 
echo "Creation docker network - simple-api-network"
docker network create simple-api-network

# Construction de l’image Docker php-apache-jean
cd "$WORKSPACE_DOCKER" || exit
echo "Construction de l'image Docker - php-apache-jean..."
docker build --no-cache -t php-apache-jean .
sleep 2

# Connexion à Docker Hub
echo "Connexion à Docker Hub..."
echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
sleep 2
# Vérification de l’authentification
if [ $? -ne 0 ]; then
    echo "Échec de la connexion à Docker Hub"
    exit 1
fi
sleep 1
# Taguer et pousser l'image Docker - simple-api-jean
echo "Préparation de l'image - simple-api-jean pour Docker Hub..."
docker tag simple-api-jean "$DOCKER_USER/simple-api-jean:latest"
sleep 3
echo "Envoi de l'image simple-api-jean vers Docker Hub..."
docker push "$DOCKER_USER/simple-api-jean:latest" &> /dev/null &  # Exécution en arrière-plan
sleep 5

# Taguer et pousser l'image Docker - php-apache-jean
echo "Préparation de l'image - php-apache-jean pour Docker Hub..."
docker tag php-apache-jean "$DOCKER_USER/php-apache-jean:latest"
sleep 3
echo "Envoi de l'image php-apache-jean vers Docker Hub..."
docker push "$DOCKER_USER/php-apache-jean:latest" &> /dev/null &  # Exécution en arrière-plan
disown
echo "L'envoi des images simple-api-jean et php-apache-jean est en cours en arrière-plan..."