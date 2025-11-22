#!/bin/bash
set -e

# Déploiement auto de Dolibarr et GLPI sur Debian

DOLIBARR_VERSION="22.0.3"
GLPI_VERSION="11.0.2"
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
      "https://www.dolibarr.org/files/stable/standard/dolibarr-${DOLIBARR_VERSION}.tgz" \
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

download_and_install_glpi() {
  log_info "Installation de GLPI ${GLPI_VERSION}..."

  cd /tmp

  if [ -f "/opt/archives/glpi-${GLPI_VERSION}.tgz" ]; then
    cp "/opt/archives/glpi-${GLPI_VERSION}.tgz" .
    log_info "Archive locale GLPI utilisée."
  else
    wget -q "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz"
  fi

  tar -xzf "glpi-${GLPI_VERSION}.tgz" -C "${WEB_ROOT}/"

  chown -R www-data:www-data "${WEB_ROOT}/glpi"
  chmod -R 755 "${WEB_ROOT}/glpi"

  mkdir -p /var/lib/glpi /var/log/glpi
  chown -R www-data:www-data /var/lib/glpi /var/log/glpi
  chmod -R 755 /var/lib/glpi /var/log/glpi

  log_info "GLPI installé dans ${WEB_ROOT}/glpi."
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

configure_hosts() {
  log_info "Mise à jour du fichier /etc/hosts..."

  grep -q "dolibarr.${DOMAIN_NAME}" /etc/hosts || \
    echo "127.0.0.1 dolibarr.${DOMAIN_NAME}" >> /etc/hosts

  grep -q "glpi.${DOMAIN_NAME}" /etc/hosts || \
    echo "127.0.0.1 glpi.${DOMAIN_NAME}" >> /etc/hosts

  log_info "Entrées hosts ajoutées pour Dolibarr et GLPI."
}

create_default_index() {
  log_info "Création de la page d'accueil /var/www/html/index.html..."

  mkdir -p /var/www/html

  cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Serveur d'applications – 4IW</title>
    <style>
        body {
            font-family: system-ui, sans-serif;
            margin: 0;
            padding: 2rem;
            background: #f4f4f4;
        }
        h1 { margin-bottom: .5rem; }
        .box {
            background: #fff;
            border: 1px solid #ddd;
            padding: 1.5rem;
            max-width: 700px;
        }
        ul { line-height: 1.8; }
        a { color: #0055aa; text-decoration: none; }
        a:hover { text-decoration: underline; }
        code { background: #eee; padding: 0 .25rem; }
    </style>
</head>
<body>
<div class="box">
    <h1>Serveur d'applications</h1>
    <p>Instance de test pour le déploiement automatisé de Dolibarr et GLPI.</p>

    <h2>Applications</h2>
    <ul>
        <li><a href="https://dolibarr.localhost">Dolibarr (HTTPS)</a></li>
        <li><a href="https://glpi.localhost">GLPI (HTTPS)</a></li>
    </ul>

    <h2>Certificat de l'autorité</h2>
    <p>
        Le certificat racine utilisé pour signer les certificats serveurs est
        disponible ici : <a href="/certs/">/certs/</a>.
    </p>
</div>
</body>
</html>
EOF

  log_info "Page d'accueil créée."
}


test_installations() {
  log_info "Redémarrage des services..."
  systemctl restart apache2
  systemctl restart mariadb

  echo
  log_info "Tests d'accès :"

  echo "- Page d'accueil (Apache par défaut) :"
  curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" http://localhost || true

  echo "- Dolibarr (code 200/302 attendu quand SSL sera configuré) :"
  curl -k -s -o /dev/null -w "Code HTTP: %{http_code}\n" https://dolibarr.${DOMAIN_NAME} || true

  echo "- GLPI (code 200/302 attendu quand SSL sera configuré) :"
  curl -k -s -o /dev/null -w "Code HTTP: %{http_code}\n" https://glpi.${DOMAIN_NAME} || true
}

display_summary() {
  echo
  echo "====================================="
  echo " Installation terminée (partie base) "
  echo "====================================="
  echo
  echo "Applications :"
  echo "  - Dolibarr : https://dolibarr.${DOMAIN_NAME}"
  echo "  - GLPI     : https://glpi.${DOMAIN_NAME}"
  echo
  echo "Bases de données :"
  echo "  - dolibarr (user: dolibarr / pass: dolibarr_pass)"
  echo "  - glpi     (user: glpi / pass: glpi_pass)"
  echo
  echo "Fichier hosts :"
  echo "  - entrées ajoutées pour dolibarr.localhost et glpi.localhost"
  echo
}

main() {
  install_prerequisites
  download_and_install_dolibarr
  download_and_install_glpi
  setup_databases
  configure_hosts
  create_default_index
  test_installations
  display_summary
}

main
