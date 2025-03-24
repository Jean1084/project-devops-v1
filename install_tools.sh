#!/bin/bash
VERSION_STRING="5:23.0.6-1~ubuntu.20.04~focal"
ENABLE_ZSH=true
WHOAMI=vagrant

# Mise à jour des paquets et installation des dépendances
sudo apt-get update
sudo apt-get install ca-certificates curl -y

# Ajout de la clé GPG officielle de Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Ajout du dépôt Docker aux sources APT
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installation de Docker et de ses composants
sudo apt-get update
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y

# Vérification et correction du lien symbolique pour docker-compose
if [ ! -f /usr/local/bin/docker-compose ]; then
    sudo ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
fi

# Démarrage et activation de Docker au démarrage
sudo systemctl start docker
sudo systemctl enable docker

# Ajout de l'utilisateur actuel au groupe Docker si l'installation de docker se faisait sur une vm ubuntu sans passer par vagrant => $(whoami)
sudo usermod -aG docker $WHOAMI

# Activation du pont réseau
sudo echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# Installation de Zsh et Git si activé
if [[ !(-z "$ENABLE_ZSH")  &&  ($ENABLE_ZSH == "true") ]]
then
    echo "Installation de Zsh et Git..."
    sudo apt -y install zsh git
    echo "$WHOAMI" | chsh -s /bin/zsh $WHOAMI
    su - $WHOAMI -c  'echo "Y" | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    su - $WHOAMI -c "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    sed -i 's/^plugins=/#&/' /home/vagrant/.zshrc
    echo "plugins=(git docker docker-compose colored-man-pages aliases copyfile copypath dotenv zsh-syntax-highlighting jsontools)" >> /home/vagrant/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME='agnoster'/g"  /home/vagrant/.zshrc
else
    echo "Zsh ne sera pas installé."
fi

# Installation de openssh-server
sudo apt install openssh-server -y

# Ouverture du port SSH le port par defaut est : 22
ss -tnlp | grep ssh

# Affichage de l'adresse IP
IP_ADDRESS=$(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p')
echo "Pour cette stack, vous utiliserez l'adresse IP : $IP_ADDRESS"