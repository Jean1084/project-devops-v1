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
docker image prune -f -a

# Construction de l’image Docker
cd "$WORKSPACE_DOCKER" || exit
echo "Construction de l'image Docker..."
docker build --no-cache -t simple-api-jean .

# Creation docker network 
echo "Creation docker network - simple-api-network"
docker network create simple-api-network

# Lancer le container de l'image simple-api-jean
echo "Lancer le container de l'image simple-api-jean"
docker run -d --network simple-api-network --name test-simple-api -v ${PWD}/student_age.json:/data/student_age.json -p 4000:5000 simple-api-jean:latest

# Pour tester API
# curl -u jean:agree -X GET http://127.0.0.1:4000/simple-jean/api/v1.0/get_student_ages


# Connexion à Docker Hub
echo "Connexion à Docker Hub..."
echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

# Vérification de l’authentification
if [ $? -ne 0 ]; then
    echo "Échec de la connexion à Docker Hub"
    exit 1
fi

# Taguer et pousser l'image Docker
echo "Préparation de l'image..."
docker tag simple-api-jean "$DOCKER_USER/simple-api-jean:latest"

echo "Envoi de l'image vers Docker Hub..."
docker push "$DOCKER_USER/simple-api-jean:latest" &> /dev/null &  # Exécution en arrière-plan
disown
echo "L'envoi de l'image est en cours en arrière-plan..."