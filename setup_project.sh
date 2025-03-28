#!/bin/bash

# Charger les variables d'environnement
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Erreur : Fichier .env introuvable !"
    exit 1
fi

WORKSPACE_PROJECT="/home/vagrant/workspace"
SSH_KEY_PATH="/home/vagrant/.ssh/id_rsa"
DIR_DOCKER_SIMPLE_API="/home/vagrant/workspace/simple_api"
DIR_DOCKER_WEB_API="/home/vagrant/workspace/website"

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
cd "$DIR_DOCKER_SIMPLE_API" || exit
echo "Construction de l'image Docker - simple-api-jean..."
docker build --no-cache -t simple-api-jean .
sleep 2

# Construction de l’image Docker php-apache-jean
cd "$DIR_DOCKER_WEB_API" || exit
echo "Construction de l'image Docker - php-apache-jean..."
docker build --no-cache -t php-apache-jean .
sleep 2

# Connexion à Docker Hub
cd "$WORKSPACE_PROJECT"
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

wait  # Attendre la fin des pushs en arrière-plan

# Nettoyage des images locales
docker rmi -f simple-api-jean "$DOCKER_USER/simple-api-jean" || true
docker rmi -f php-apache-jean "$DOCKER_USER/php-apache-jean" || true
docker image prune -f


cd "$DIR_DOCKER_WEB_API" || exit
echo "reconstruction de l'image Docker - php-apache-jean pour lancer docker-compose..."
docker build -t php-apache-jean:latest .
sleep 5
cd "$DIR_DOCKER_SIMPLE_API" || exit
echo "reconstruction de l'image Docker - simple-api-jean pour lancer docker-compose..."
docker build -t simple-api-jean:latest .
sleep 5

cd "$WORKSPACE_PROJECT"
echo "Lancer docker-compose up ..."
docker-compose up -d --build

echo "L'envoi des images simple-api-jean et php-apache-jean est en cours en arrière-plan..."
echo "**************************************************************************************************"
echo "Faire 'vagrant ssh' pour se connecter"
echo "**************************************************************************************************"
echo "Pour tester 'curl -u jean:agree -X GET http://127.0.0.1:4000/simple-jean/api/v1.0/get_student_ages'"
echo "**************************************************************************************************"
echo "ou 'curl -u jean:agree -X GET http://localhost:4000/simple-jean/api/v1.0/get_student_ages'"