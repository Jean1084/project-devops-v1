FROM debian:bullseye

LABEL maintainer="Jean JOSEPH <josephjeanmardochee@gmail.com>"

# Définit le dossier de travail
WORKDIR /app

# Copie le script Python
COPY student_age.py .

# Copie le fichier des dépendances
COPY requirements.txt .

# Installation de Python, pip et des dépendances système nécessaires
RUN apt update -y && apt install -y python3 python3-pip python3-dev libsasl2-dev libldap2-dev libssl-dev

# Installation des paquets Python définis dans requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

VOLUME ["/data"]
EXPOSE 5000

CMD ["python3", "student_age.py"]