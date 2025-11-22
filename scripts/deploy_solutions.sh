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

main() {
  install_prerequisites
}

main
