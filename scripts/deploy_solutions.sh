#!/bin/bash
set -e

# Déploiement auto de Dolibarr et GLPI sur Debian

DOLIBARR_VERSION="18.0.3"
GLPI_VERSION="10.0.11"
DOMAIN_NAME="localhost"
CA_DIR="/etc/ssl/myca"
CERT_DIR="/etc/apache2/ssl"
WEB_ROOT="/var/www"
DB_ROOT_PASS="root_password"

log_info() {
  echo "[INFO] $1"
}

log_error() {
  echo "[ERROR] $1" >&2
  exit 1
}

install_prerequisites() {
  log_info "Installation des paquets necessaires (Apache, MariaDB, PHP)..."

  apt-get update
  apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    php-xml \
    php-mbstring \
    php-curl \
    php-gd \
    php-intl \
    php-ldap \
    php-apcu \
    php-xmlrpc \
    php-zip \
    php-bz2 \
    php-soap \
    wget \
    unzip \
    openssl \
    apache2-utils

  a2enmod ssl
  a2enmod rewrite
  a2enmod headers

  log_info "Installation des paquets terminée."
}

download_and_install_dolibarr() {
  log_info "Installation de Dolibarr ${DOLIBARR_VERSION}..."

  cd /tmp

  # Utiliser l'archive locale si bug passe en ligne
  if [ -f "/opt/archives/dolibarr-${DOLIBARR_VERSION}.tgz" ]; then
    cp "/opt/archives/dolibarr-${DOLIBARR_VERSION}.tgz" .
    log_info "Utilisation de l'archive locale Dolibarr."
  else
    wget -q \
      "https://sourceforge.net/projects/dolibarr/files/Dolibarr%20ERP-CRM/${DOLIBARR_VERSION}/dolibarr-${DOLIBARR_VERSION}.tgz/download" \
      -O "dolibarr-${DOLIBARR_VERSION}.tgz"
  fi

  tar -xzf "dolibarr-${DOLIBARR_VERSION}.tgz" -C "${WEB_ROOT}/"
  mv "${WEB_ROOT}/dolibarr-${DOLIBARR_VERSION}" "${WEB_ROOT}/dolibarr"

  chown -R www-data:www-data "${WEB_ROOT}/dolibarr"
  chmod -R 755 "${WEB_ROOT}/dolibarr"

  mkdir -p /var/lib/dolibarr/documents
  chown -R www-data:www-data /var/lib/dolibarr
  chmod -R 755 /var/lib/dolibarr

  log_info "Dolibarr installé dans ${WEB_ROOT}/dolibarr."
}

setup_databases() {
  log_info "Configuration des bases de données..."

  mysql -u root -p"${DB_ROOT_PASS}" -e \
    "CREATE DATABASE IF NOT EXISTS dolibarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql -u root -p"${DB_ROOT_PASS}" -e \
    "CREATE USER IF NOT EXISTS 'dolibarr'@'localhost' IDENTIFIED BY 'dolibarr_pass';"
  mysql -u root -p"${DB_ROOT_PASS}" -e \
    "GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr'@'localhost';"

  mysql -u root -p"${DB_ROOT_PASS}" -e \
    "CREATE DATABASE IF NOT EXISTS glpi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql -u root -p"${DB_ROOT_PASS}" -e \
    "CREATE USER IF NOT EXISTS 'glpi'@'localhost' IDENTIFIED BY 'glpi_pass';"
  mysql -u root -p"${DB_ROOT_PASS}" -e \
    "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"

  mysql -u root -p"${DB_ROOT_PASS}" -e "FLUSH PRIVILEGES;"

  log_info "Bases de données Dolibarr et GLPI créées."
}


main() {
  install_prerequisites
  download_and_install_dolibarr
  setup_databases
}

main
