# -*- mode: ruby -*-
# vi: set ft=ruby :
# To enable zsh, please set ENABLE_ZSH env var to "true" before launching vagrant up 
#   + On Windows => $env:ENABLE_ZSH="true"
#   + On Linux   => export ENABLE_ZSH="true"

# === Configuration globale ===
BOX_NAME       = "ubuntu/focal64"
BOX_VERSION    = "20240821.0.1"
VM_NAME        = "vm-workspace"
VM_HOSTNAME    = "jean"
VM_IP          = "192.168.56.10"
VM_MEMORY      = 4096
VM_CPUS        = 4
INSTALL_SCRIPT = "install_tools.sh"
GITHUB_SSH_SCRIPT = "add_github_ssh.sh"
SETUP_PROJECT_SCRIPT = "setup_project.sh"

Vagrant.configure("2") do |config|
  config.vm.box = BOX_NAME
  config.vm.box_version = BOX_VERSION
  config.vm.network "private_network", type: "static", ip: VM_IP
  config.vm.hostname = VM_HOSTNAME

  # Synchronisation du fichier .env via un lien symbolique
  config.vm.synced_folder ".", "/home/vagrant/workspace", type: "virtualbox"
  config.vm.provision "shell", inline: <<-SHELL
    ln -sf /home/vagrant/workspace/.env /home/vagrant/.env
  SHELL

  # Configuration du provider VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.name = VM_NAME
    vb.memory = VM_MEMORY
    vb.cpus = VM_CPUS
  end

  # Synchronisation du dossier local avec /vagrant sur la VM
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  # Provisioning : Installation des outils
  config.vm.provision :shell do |shell|
    shell.path = INSTALL_SCRIPT
    shell.env = { 'ENABLE_ZSH' => ENV['ENABLE_ZSH'] || "false" }
  end

  # Vérification et installation de Docker si nécessaire
  config.vm.provision "shell", inline: <<-SHELL
    echo "Nettoyer les paquets inutiles pour libérer de l'espace..."
    sudo apt-get autoremove -y
    sudo apt-get clean

    # Charger les variables d'environnement
    if [ -f .env ]; then
      export $(grep -v '^#' .env | xargs)
    else
      echo "Erreur : Fichier .env introuvable !"
      exit 1
    fi

  # Activer et redémarrer Docker
    echo "Activation et démarrage du service Docker..."
    sudo systemctl enable docker
    sudo systemctl restart docker

  # Vérifier si Docker est actif
    if ! systemctl is-active --quiet docker; then
      echo "ERREUR : Docker ne démarre pas correctement !"
      exit 1
    fi

  # Ajouter vagrant au groupe docker
    echo "Ajout de l'utilisateur vagrant au groupe docker..."
    sudo usermod -aG docker vagrant
    echo "Redémarrage du shell pour appliquer les permissions..."
    newgrp docker
  SHELL
  
  # Provisioning : Ajout de la clé SSH pour GitHub
  config.vm.provision :shell, path: GITHUB_SSH_SCRIPT

  # Provisioning : Setup project après le clonage Git
  config.vm.provision :shell, path: SETUP_PROJECT_SCRIPT
end
