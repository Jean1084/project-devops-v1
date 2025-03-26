#!/bin/bash

source .env

# Chemin de la clé SSH
SSH_DIR="/home/vagrant/.ssh"
SSH_KNOWN_HOSTS="/home/vagrant/.ssh/known_hosts"
SSH_KEY_PATH="$SSH_DIR/id_rsa"
SSH_PUB_KEY_PATH="$SSH_KEY_PATH.pub"

# Vérifier et créer le dossier .ssh si nécessaire
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chown vagrant:vagrant "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Vérifier si une clé SSH existe, sinon la générer
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "Clé SSH non trouvée, création en cours..."
    ssh-keygen -t rsa -b 4096 -C "$GITHUB_USER@github.com" -f "$SSH_KEY_PATH" -N "" -q
    echo "Clé SSH générée !"
else
    echo "Clé SSH existante détectée."
fi

# Assurer que les permissions sont correctes
echo "Vérification et correction des permissions des clés..."
chown -R vagrant:vagrant "$SSH_DIR"
chmod 600 "$SSH_KEY_PATH"
chmod 644 "$SSH_PUB_KEY_PATH"

# Ajouter la clé GitHub au fichier known_hosts pour éviter la demande interactive
echo "Ajout de GitHub aux hôtes connus si nécessaire..."
touch "$SSH_KNOWN_HOSTS"
chown -R vagrant:vagrant "$SSH_KNOWN_HOSTS"
chmod 644 "$SSH_KNOWN_HOSTS"
grep -q "github.com" "$SSH_KNOWN_HOSTS" || ssh-keyscan -H github.com 2>/dev/null | tee -a >> "$SSH_KNOWN_HOSTS"


# On verifie a qui appartient la cle id_rsa et id_rsa.pub 
echo "On verifie a qui appartient le fichier known_hosts"
ls -la "$SSH_KNOWN_HOSTS"

# Lire la clé publique
SSH_KEY_CONTENT=$(cat "$SSH_PUB_KEY_PATH")

# Ajouter la clé sur GitHub via l'API
echo "Ajout de la clé sur GitHub..."
RESPONSE=$(curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/keys \
    -d "{\"title\":\"ssh_key_vm_docker_vagrant\", \"key\":\"$SSH_KEY_CONTENT\"}")

# Vérifier si l'ajout a réussi
if echo "$RESPONSE" | grep -q '"key":'; then
    echo "Clé SSH ajoutée avec succès sur GitHub !"
else
    echo "Erreur lors de l'ajout de la clé. Vérifiez votre token."
    echo "Réponse GitHub : $RESPONSE"
    exit 1
fi

# Vérifier que la clé SSH est bien ajoutée à l'agent SSH
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH"

echo "Test de connexion à GitHub..."
if ssh -o StrictHostKeyChecking=accept-new -i "$SSH_KEY_PATH" -T git@github.com -v 2>&1 | grep -q "successfully authenticated"; then
    echo "Connexion SSH à GitHub réussie !"
else
    echo "Échec de la connexion SSH à GitHub."
    exit 1
fi