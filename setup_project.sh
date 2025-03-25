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

# Change directory Dockerfile
# cd "$WORKSPACE_DOCKER"

# Create image
# docker build -t simple-api-jean .

# Connexion a Docker
# echo "Connexion à Docker avec l'utilisateur : $DOCKER_USER"
# echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin 

# Preparation de l'image
# docker tag simple-api-jean jean1084/simple-api-jean:latest

# Envoi de l'image sur Docker hub
# docker push jean1084/simple-api-jean:latest