#!/bin/bash

WORKSPACE_DIR="/home/vagrant/workspace"

# Démarrer l'agent SSH et charger la clé
eval "$(ssh-agent -s)"
ssh-add /home/vagrant/.ssh/id_rsa
sleep 2

# Créer le dossier workspace
echo "create folder workspace and change dir"
mkdir -p "$WORKSPACE_DIR"
chown vagrant:vagrant "$WORKSPACE_DIR"
chmod 700 "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Cloner le dépôt
if [ ! -d "$WORKSPACE_DIR/project-devops-v1" ]; then
    echo "git clone project in /home/vagrant/workspace"
    sudo -u vagrant -H bash -c 'GIT_SSH_COMMAND="ssh -i /home/vagrant/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git clone git@github.com:Jean1084/project-devops-v1.git'
    chown -R vagrant:vagrant "$WORKSPACE_DIR/project-devops-v1"
    chmod -R 700 "$WORKSPACE_DIR/project-devops-v1"
    echo "git clone done!"
else
    echo "git clone failed! Directory already exists."
    exit 1
fi
