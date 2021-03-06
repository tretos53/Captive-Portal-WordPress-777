#!/bin/bash

:<<"USAGE"
$0 Filename captiveportal.sh
$1 SSID
USAGE

if [ "$EUID" -ne 0 ]
	then echo "Must be root, run sudo -i before running that script."
	exit
fi

SSID=${1:-CaptivePortal01}

echo "┌─────────────────────────────────────────"
echo "|This script might take a while,"
echo "|so if you dont see much progress,"
echo "|wait till you see --all done-- message."
echo "└─────────────────────────────────────────"
read -p -r "Press enter to continue"

echo "┌─────────────────────────────────────────"
echo "|Updating repositories"
echo "└─────────────────────────────────────────"
apt-get update -yqq

# echo "┌─────────────────────────────────────────"
# echo "|Upgrading packages, this might take a while|"
# echo "└─────────────────────────────────────────"
# apt-get upgrade -yqq

echo "┌─────────────────────────────────────────"
echo "|Installing and configuring nginx"
echo "└─────────────────────────────────────────"
apt-get install nginx -yqq
wget -q https://raw.githubusercontent.com/tretos53/Captive-Portal-WordPress/master/default_nginx -O /etc/nginx/sites-enabled/default

echo "┌─────────────────────────────────────────"
echo "|Installing dnsmasq"
echo "└─────────────────────────────────────────"
apt-get install dnsmasq -yqq

echo "┌─────────────────────────────────────────"
echo "|Configuring wlan0"
echo "└─────────────────────────────────────────"
wget -q https://raw.githubusercontent.com/tretos53/Captive-Portal/master/dhcpcd.conf -O /etc/dhcpcd.conf

echo "┌─────────────────────────────────────────"
echo "|Configuring dnsmasq"
echo "└─────────────────────────────────────────"
wget -q https://raw.githubusercontent.com/tretos53/Captive-Portal/master/dnsmasq.conf -O /etc/dnsmasq.conf

echo "┌─────────────────────────────────────────"
echo "|configuring dnsmasq to start at boot"
echo "└─────────────────────────────────────────"
update-rc.d dnsmasq defaults

echo "┌─────────────────────────────────────────"
echo "|Installing hostapd"
echo "└─────────────────────────────────────────"
apt-get install hostapd -yqq

echo "┌─────────────────────────────────────────"
echo "|Configuring hostapd"
echo "└─────────────────────────────────────────"
wget -q https://raw.githubusercontent.com/tretos53/Captive-Portal/master/hostapd.conf -O /etc/hostapd/hostapd.conf
sed -i -- 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd
sed -i -- "s/CaptivePortal01/${SSID}/g" /etc/hostapd/hostapd.conf

echo "┌─────────────────────────────────────────"
echo "|Configuring iptables"
echo "└─────────────────────────────────────────"
iptables -t nat -A PREROUTING -s 192.168.24.0/24 -p tcp --dport 80 -j DNAT --to-destination 192.168.24.1:80
iptables -t nat -A POSTROUTING -j MASQUERADE
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
apt-get -y install iptables-persistent

echo "┌─────────────────────────────────────────"
echo "|configuring hostapd to start at boot"
echo "└─────────────────────────────────────────"
systemctl unmask hostapd.service
systemctl enable hostapd.service

echo "┌─────────────────────────────────────────"
echo "|Installing MySQL"
echo "└─────────────────────────────────────────"
apt-get install mariadb-server -yqq > /dev/null
mysql_secure_installation <<EOF
y
Pa55w04d123
Pa55w04d123
y
y
y
y
EOF

dbsetup="create database wordpress;GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@$localhost IDENTIFIED BY 'Pa55w04d123$';FLUSH PRIVILEGES;"
mysql -e "$dbsetup"

echo "┌─────────────────────────────────────────"
echo "|Installing PHP"
echo "└─────────────────────────────────────────"

apt-get install php7.3-fpm php7.3-mbstring php7.3-mysql php7.3-curl php7.3-gd php7.3-curl php7.3-zip php7.3-xml -yqq > /dev/null

systemctl restart php7.3-fpm

echo "┌─────────────────────────────────────────"
echo "|Installing Wordpress"
echo "└─────────────────────────────────────────"
curl -o /var/www/latest.tar.gz -O https://wordpress.org/latest.tar.gz
tar -C /var/www/ -zxvf /var/www/latest.tar.gz
wget -q https://raw.githubusercontent.com/tretos53/Captive-Portal-WordPress/master/wp-config.php -O /var/www/wordpress/wp-config.php
chown -R www-data:www-data /var/www/wordpress
SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/wordpress/wp-config.php

echo "┌─────────────────────────────────────────"
echo "|Configuring system logs"
echo "└─────────────────────────────────────────"
wget -q https://raw.githubusercontent.com/tretos53/Captive-Portal-777/master/system_status.sh -O /home/cybershark/system_status.sh
wget -q https://raw.githubusercontent.com/tretos53/Captive-Portal-777/master/logrotate.conf -O /etc/logrotate.conf
echo "0 13 * * * bash /home/cybershark/system_status.sh >> /home/cybershark/systemstatus.log" | crontab -

echo "┌─────────────────────────────────────────"
echo "|Reboot and test"
echo "└─────────────────────────────────────────"
