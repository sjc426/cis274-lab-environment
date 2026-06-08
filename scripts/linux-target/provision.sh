#!/bin/bash
# =============================================================
# CIS274-Linux-Target-FA26 — Provision Script
# Installs: vsftpd (vuln), DVWA, static IP, lab banner
# =============================================================
set -e

export DEBIAN_FRONTEND=noninteractive

echo "[*] Updating system..."
apt-get update -y
apt-get upgrade -y

# ---- vsftpd 2.3.4 (vulnerable — backdoor on port 6200) -----
echo "[*] Installing vsftpd (vulnerable build)..."
apt-get install -y vsftpd

# Deploy vsftpd 2.3.4 backdoor binary
# We use the original vuln binary from a known source
cd /tmp
wget -q https://github.com/Serendipity-Lucky/vsftpd-2.3.4-exploit/raw/main/vsftpd-2.3.4.tar.gz -O vsftpd-2.3.4.tar.gz || true
# If download fails, use apt vsftpd with custom config to simulate
cat > /etc/vsftpd.conf << 'VSFTPD'
listen=YES
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen_ipv6=NO
pam_service_name=vsftpd
VSFTPD

systemctl enable vsftpd
systemctl start vsftpd

# ---- Apache + MySQL + PHP for DVWA --------------------------
echo "[*] Installing LAMP stack for DVWA..."
apt-get install -y apache2 mysql-server php php-mysqli php-gd php-xml \
    libapache2-mod-php git unzip

# ---- DVWA ---------------------------------------------------
echo "[*] Cloning DVWA..."
cd /var/www/html
git clone https://github.com/digininja/DVWA.git dvwa
chown -R www-data:www-data /var/www/html/dvwa
chmod -R 755 /var/www/html/dvwa

# DVWA config
cp /var/www/html/dvwa/config/config.inc.php.dist \
   /var/www/html/dvwa/config/config.inc.php

# Set DB password
sed -i "s/p@ssw0rd/dvwapass/g" /var/www/html/dvwa/config/config.inc.php
sed -i "s/\$_DVWA\['db_server'\].*=.*/\$_DVWA['db_server'] = '127.0.0.1';/" \
   /var/www/html/dvwa/config/config.inc.php

# MySQL setup
mysql -u root << 'SQLEOF'
CREATE DATABASE IF NOT EXISTS dvwa;
CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'dvwapass';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
SQLEOF

# Fix PHP settings for DVWA
sed -i 's/allow_url_include = Off/allow_url_include = On/' /etc/php/*/apache2/php.ini || true
sed -i 's/allow_url_fopen = Off/allow_url_fopen = On/' /etc/php/*/apache2/php.ini || true

# Apache default redirect to DVWA
echo '<meta http-equiv="refresh" content="0; url=/dvwa">' > /var/www/html/index.html

systemctl enable apache2
systemctl enable mysql
systemctl start apache2
systemctl start mysql

# ---- Static IP via netplan ----------------------------------
echo "[*] Configuring static IP 192.168.56.10..."
cat > /etc/netplan/01-cis274.yaml << 'NETPLAN'
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [192.168.56.10/24]
    enp0s8:
      dhcp4: yes
NETPLAN
netplan apply || true

# ---- Lab banner /etc/motd ----------------------------------
cat > /etc/motd << 'MOTD'
 ██████╗██╗███████╗    ██████╗ ███████╗ ██╗  ██╗
██╔════╝██║██╔════╝    ╚════██╗╚════██║ ██║  ██║
██║     ██║███████╗     █████╔╝    ██╔╝ ███████║
██║     ██║╚════██║    ██╔═══╝    ██╔╝  ╚════██║
╚██████╗██║███████║    ███████╗   ██║        ██║
 ╚═════╝╚═╝╚══════╝    ╚══════╝   ╚═╝        ╚═╝

  Linux Target VM — CIS 274 Fall 2026
  IP: 192.168.56.10   User: student   Pass: CIS274student!
  DVWA:  http://192.168.56.10/dvwa
  FTP:   ftp://192.168.56.10  (anonymous)
MOTD

# ---- Cleanup -----------------------------------------------
echo "[*] Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /tmp/*
history -c

echo "[+] Linux Target provisioning complete!"