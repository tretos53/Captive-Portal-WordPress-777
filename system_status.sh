#!/bin/bash

current_date_time=$(date '+%d/%m/%Y %H:%M:%S');
current_uptime=$(uptime);
service_nginx=$(systemctl status nginx.service | grep Active);
service_php=$(systemctl status php7.3-fpm.service | grep Active);
service_dhcp=$(systemctl status dhcpcd.service | grep Active);
service_dnsmasq=$(systemctl status dnsmasq.service | grep Active);
service_hostapd=$(systemctl status hostapd.service | grep Active);
service_logrotate=$(systemctl status logrotate.service | grep Active);
service_networking=$(systemctl status networking.service | grep Active);
service_ssh=$(systemctl status ssh.service | grep Active);
service_system=$(systemctl is-system-running);
service_cron=$(systemctl status cron.service | grep Active);

echo ""
echo "┌─────────────────────────────────────────"
echo "│System Status:"
echo "│ - Date: $current_date_time"
echo "│ - Uptime: $current_uptime"
echo "│"
echo "│Services:"
echo "│ - NGINX: $service_nginx"
echo "│ - PHP: $service_php"
echo "│ - DHCP: $service_dhcp"
echo "│ - DNSMasq: $service_dnsmasq"
echo "│ - Hostapd: $service_hostapd"
echo "│ - Cron: $service_cron"
echo "│ - Logrotate: $service_logrotate"
echo "│ - Networking: $service_networking"
echo "│ - SSH: $service_ssh"
echo "│ - Cron: $service_cron"
echo "│"
echo "│System"
echo "│ - System: $service_system"
echo "└─────────────────────────────────────────"
echo ""
