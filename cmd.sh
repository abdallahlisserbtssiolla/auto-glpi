#!/bin/bash

# Script d'installation de GLPI 10.0.16 sur Debian 12

# Mise à jour des paquets
apt-get update && apt-get upgrade -y


# Installation du socle LAMP
apt-get install -y apache2 mariadb-server php php8.2-fpm

# Installation des extensions PHP nécessaires pour GLPI
apt-get install -y php-xml php-common php-json php-mysql php-mbstring php-curl php-gd php-intl php-zip php-bz2 php-imap php-apcu php-ldap

# Sécurisation de MariaDB


# Création de la base de données GLPI et utilisateur dédié
mysql -u root -pnewpassword <<EOF
CREATE DATABASE db23_glpi;
GRANT ALL PRIVILEGES ON db23_glpi.* TO 'glpi_adm'@'localhost' IDENTIFIED BY 'Glpi@2024=+';
FLUSH PRIVILEGES;
EXIT;
EOF

# Téléchargement de GLPI 10.0.16
cd /tmp
wget https://github.com/glpi-project/glpi/releases/download/10.0.16/glpi-10.0.16.tgz

# Décompression de l'archive
tar -xzvf glpi-10.0.16.tgz -C /var/www/

# Modification des droits pour Apache (www-data)
chown www-data:www-data /var/www/glpi/ -R

# Création des répertoires sécurisés pour GLPI
mkdir /etc/glpi /var/lib/glpi /var/log/glpi
chown www-data:www-data /etc/glpi /var/lib/glpi /var/log/glpi

# Déplacement des dossiers de GLPI vers des emplacements sécurisés
mv /var/www/glpi/config /etc/glpi/
mv /var/www/glpi/files /var/lib/glpi/

# Configuration de GLPI pour utiliser ces nouveaux chemins
echo "<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}" > /var/www/glpi/inc/downstream.php

echo "<?php
define('GLPI_VAR_DIR', '/var/lib/glpi/files');
define('GLPI_LOG_DIR', '/var/log/glpi');
" > /etc/glpi/local_define.php

# Configuration d'Apache2 pour GLPI
echo "<VirtualHost *:80>
    ServerName glpi.local

    DocumentRoot /var/www/glpi/public

    <Directory /var/www/glpi/public>
        Require all granted
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/glpi.conf

# Activation du site GLPI et modules nécessaires
a2ensite glpi.conf
a2enmod rewrite proxy_fcgi setenvif
a2enconf php8.2-fpm

# Redémarrage d'Apache
systemctl restart apache2

# Configurer PHP-FPM pour Apache2
sed -i "s/;session.cookie_httponly =/session.cookie_httponly = on/" /etc/php/8.2/fpm/php.ini

# Redémarrage de PHP-FPM
systemctl restart php8.2-fpm

echo "Installation terminée. Accédez à GLPI via http://glpi.local"
