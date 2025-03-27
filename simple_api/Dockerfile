FROM debian:bullseye

LABEL maintainer="Jean JOSEPH <josephjeanmardochee@gmail.com>"

WORKDIR /app

# Installation de Python et des dépendances en une seule couche
RUN apt update -y && \
    apt install -y python3 python3-pip python3-dev libsasl2-dev libldap2-dev libssl-dev

# Réduit la taille de l'image    
RUN rm -rf /var/lib/apt/lists/*  

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY student_age.py .

# Définir un utilisateur non-root pour exécuter l'application
# RUN useradd -m appuser
# USER appuser

VOLUME ["/data"]

EXPOSE 5000

CMD ["python3", "student_age.py"]