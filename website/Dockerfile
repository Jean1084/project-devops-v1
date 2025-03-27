FROM php:8.2-apache

LABEL maintainer="Jean JOSEPH <josephjeanmardochee@gmail.com>"

WORKDIR /var/www/html

# Installation optimisée des extensions PHP
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd mysqli pdo pdo_mysql

# Réduit la taille de l'image    
RUN rm -rf /var/lib/apt/lists/*      

RUN a2enmod rewrite

# Configuration des droits et des permissions
# RUN chown -R www-data:www-data /var/www/html/

# Copie des fichiers de l'application (remplacez par votre projet)
# COPY . /var/www/html/

# Définir un utilisateur non-root
# RUN useradd -m appuser
# USER appuser

EXPOSE 80

CMD ["apache2-foreground"]