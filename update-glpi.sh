#!/bin/bash

# Vérification des arguments
if [ $# -ne 6 ]; then
    echo "Usage: $0 -v <version> -u <user_db> -p <password_db>"
    exit 1
fi

while getopts ":v:u:p:" opt; do
  case $opt in
    v) version="$OPTARG";;
    u) user_db="$OPTARG";;
    p) password_db="$OPTARG";;
    \?) echo "Option invalide -$OPTARG" >&2; exit 1;;
    :) echo "L'option -$OPTARG nécessite un argument." >&2; exit 1;;
  esac
done

# Création du dossier de sauvegarde
mkdir -p /opt/backup_glpi

# Sauvegarde de la base de données
mysqldump --user="$user_db" --password="$password_db" --databases glpi > /opt/backup_glpi/backup_glpi_DB.sql

# Sauvegarde du dossier GLPi
cp -rf /var/www/html/glpi /opt/glpi_backup

# Suppression de l'ancienne installation GLPi
rm -fr /var/www/html/glpi

# Téléchargement de la nouvelle version de GLPi
wget -q --show-progress --no-check-certificate https://github.com/glpi-project/glpi/releases/download/$version/glpi-$version.tgz -P /tmp

# Extraction de l'archive GLPi
tar xvf /tmp/glpi-$version.tgz -C /tmp

# Déplacement de la nouvelle installation GLPi
mv /tmp/glpi /var/www/html/glpi

# Copie des dossiers depuis l'ancienne installation
cp -rf /opt/glpi_backup/config /var/www/html/glpi/
cp -rf /opt/glpi_backup/files /var/www/html/glpi/
cp -rf /opt/glpi_backup/plugins /var/www/html/glpi/
cp -rf /opt/glpi_backup/marketplace /var/www/html/glpi/

# Attribution des permissions
chown -R apache:apache /var/www/html/glpi
chmod 775 /var/www/html/glpi

# Redémarrage du service Apache
systemctl restart httpd

# Vérification des erreurs
if [ $? -ne 0 ]; then
    echo "Une erreur est survenue lors du redémarrage d'Apache. Veuillez vérifier les logs."
    exit 1
fi

echo "La mise à jour de GLPi a été déployée avec succès."

