#!/bin/bash
# Deploy mail autoconfig for Plesk
# Support for Thunderbird, Outlook & iOS
# Website: haisoft.fr

# Autoconfig paths
autoconfigpath="/var/www/vhosts/default/htdocs/mail"
autoconfigfile="config-v1.1.xml"
autoconfigpathfile="${autoconfigpath}/${autoconfigfile}"

# Autodiscover paths
autodiscoverpath="/var/www/vhosts/default/htdocs/mail"
autodiscoverpathfile="${autodiscoverpath}/autodiscover.xml"
autodiscoverpathfilealt="${autodiscoverpath}/Autodiscover.xml"
autodiscoverhtaccess="${autodiscoverpath}/.htaccess"

# httpd config
httpdautodiscoverconf="/etc/httpd/conf.d/autodiscover.conf"

##############
### Script ###
##############

# Misc Vars
selfname="Mail Autoconfig"
hostname="$(hostname)"

# Download bash API
if [ ! -f "ultimate-bash-api.sh" ]; then
	wget https://raw.githubusercontent.com/UltimateByte/ultimate-bash-api/master/ultimate-bash-api.sh
	chmod +x ultimate-bash-api.sh
fi
source ultimate-bash-api.sh

fn_logecho "Mail autoconfig && autodiscover generator for Plesk"
fn_logecho "###################################"

# Files and directories creation
if [ ! -d "${autoconfigpath}" ]; then
	fn_logecho "[INFO] Creating autoconfig cofngi path"
	fn_logecho "${autoconfigpath}"
	mkdir -p "${autoconfigpath}"
fi

if [ ! -f "${autoconfigpathfile}" ]; then
	fn_logecho "[INFO] Creating autoconfig config file"
	fn_logecho "${autoconfigpathfile}"
	touch "${autoconfigpathfile}"
fi

if [ ! -d "${autodiscoverpath}" ]; then
	fn_logecho "[INFO] Creating autodiscover config path"
	fn_logecho "${autodiscoverpath}"
	mkdir -p "${autodiscoverpath}"
fi

if [ ! -f "${autodiscoverpathfile}" ]; then
	fn_logecho "[INFO] Creating autodiscover config file"
	fn_logecho "${autodiscoverpathfile}"
	touch "${autodiscoverpathfile}"
fi

if [ ! -L "${autodiscoverpathfilealt}" ]; then
	fn_logecho "[INFO] Symlinking autodiscover alternative config file"
	fn_logecho "${autodiscoverpathfile} -> ${autodiscoverpathfilealt}"
	ln -s "${autodiscoverpathfile}" "${autodiscoverpathfilealt}"
fi

if [ ! -f "${autodiscoverhtaccess}" ]; then
	fn_logecho "[INFO] Creating autodiscover .htaccess file"
	fn_logecho "${autodiscoverhtaccess}"
	touch "${autodiscoverhtaccess}"
fi

if [ ! -f "${httpdautodiscoverconf}" ]; then
	fn_logecho "[INFO] Creating autodiscover httpd configuration file"
	fn_logecho "${httpdautodiscoverconf}"
	touch "${httpdautodiscoverconf}"
fi

# Thunderbird autoconfig

fn_logecho "[INFO] Writing autoconfig config file"
curl "https://raw.githubusercontent.com/UltimateByte/plesk_mail_autoconfig/master/config-v1.1.xml" > "${autoconfigpathfile}"

fn_logecho "[INFO] Correcting default DNS zone for autoconfig"
/usr/local/psa/bin/server_dns --add -cname autoconfig -canonical "${hostname}"

fn_logecho "[INFO] Adding DNS entry for every website for autoconfig"

for i in `mysql -uadmin -p\`cat /etc/psa/.psa.shadow\` psa -Ns -e "select name from domains"`; do 
	/usr/local/psa/bin/dns --add "$i" -cname autoconfig -canonical "${hostname}"
done

# Outlook autodiscover

fn_logecho "[INFO] Writing autodiscover config file"
curl "https://raw.githubusercontent.com/UltimateByte/plesk_mail_autoconfig/master/autodiscover.xml" > "${autodiscoverpathfile}"

fn_logecho "[INFO] Writing autodiscover htaccess"
echo "AddHandler php-script .php .xml
RewriteEngine on
RewriteCond %{REQUEST_URI} !iphone.xml
RewriteCond %{REQUEST_URI} ios
RewriteRule .* /ios/iphone.xml [R]" > "${autodiscoverhtaccess}"

fn_logecho "[INFO] Writing autodiscover httpd configuration file"
echo "Alias /mail \"${autoconfigpath}\"
Alias /autodiscover \"${autodiscoverpath}\"
Alias /Autodiscover \"${autodiscoverpath}\"" > "${httpdautodiscoverconf}"

fn_logecho "[INFO] Restarting httpd"
service httpd restart

# Some testing

if [ -n "$(curl "http://autoconfig.${hostname}/mail/config-v1.1.xml" | grep "<socketType>SSL</socketType>")" ]; then
	fn_logecho "[OK] http://autoconfig.${hostname}/mail/${autoconfigfile} is accessible"
else
	fn_logecho "[ERROR!] http://autoconfig.${hostname}/mail/${autoconfigfile} does not seem to be accessible"
fi

if [ -n "$(curl "https://${hostname}/autodiscover/autodiscover.xml" | grep "<DisplayName>HaiSoft</DisplayName>")" ]; then
	fn_logecho "[OK] https://${hostname}/autodiscover/autodiscover.xml is accessible"
else
	fn_logecho "[ERROR!] https://${hostname}/autodiscover/autodiscover.xml does not seem to be accessible"
fi

if [ -n "$(curl "https://${hostname}/Autodiscover/Autodiscover.xml" | grep "<DisplayName>HaiSoft</DisplayName>")" ]; then
	fn_logecho "[OK] https://${hostname}/Autodiscover/Autodiscover.xml is accessible"
else
	fn_logecho "[ERROR!] https://${hostname}/Autodiscover/Autodiscover.xml does not seem to be accessible"
fi

fn_logecho "[INFO] Done"
