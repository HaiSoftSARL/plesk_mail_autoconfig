#!/bin/bash
# Deploy mail autoconfig for Plesk
# Support for Thunderbird autoconfig, Outlook autodiscover & iOS config generator
# Website: haisoft.net

## Settings

# These will be visible inside your config files
companyname="HaiSoft"
companyshortname="HaiSoft"
companylowercasename="haisoft"
companyurl="haisoft.net"
docurl="http://help.haisoft.net/"
hostname="$(hostname)"

# Git repo, useful if you want to fork it
gituser="UltimateByte"
gitrepo="plesk_mail_autoconfig"
gitbranch="master"

# Hosting directory
# The place where we host our configuration files
defaulthostingdir="/var/www/vhosts/default/htdocs"

# Thunderbird autoconfig paths
autoconfigpath="${defaulthostingdir}/mail"
autoconfigfile="config-v1.1.xml"
autoconfigpathfile="${autoconfigpath}/${autoconfigfile}"

# Outlook autodiscover paths
autodiscoverpath="${defaulthostingdir}/mail"
autodiscoverpathfile="${autodiscoverpath}/autodiscover.xml"
autodiscoverpathfilealt="${autodiscoverpath}/Autodiscover.xml"
autodiscoverhtaccess="${autodiscoverpath}/.htaccess"

# iOS configurator paths
iospath="${defaulthostingdir}/mail"
iphonepathfile="${iospath}/iphone.xml"
iphonemobileconfpathfile="${autodiscoverpath}/iphone.mobileconfig"
ioslogo="logo.png"
ioslogourl="https://raw.githubusercontent.com/${gituser}/${gitrepo}/${gitbranch}/${ioslogo}"

# URLs used for tests
autoconfigurl="http://autoconfig.${hostname}/mail/config-v1.1.xml"
autodiscoverurl="https://${hostname}/autodiscover/autodiscover.xml"
autodiscoverurlalt="https://${hostname}/Autodiscover/Autodiscover.xml"
iosconfigurl="http://${hostname}/ios"

# httpd config
httpdautodiscoverconf="/etc/httpd/conf.d/autodiscover.conf"

##############
### Script ###
##############

# Misc Vars
selfname="Mail Autoconfig"

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
	fn_logecho "[INFO] Creating autoconfig config path"
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

## Thunderbird autoconfig
fn_logecho "[INFO] Writing Thunderbird autoconfig config file"
curl "https://raw.githubusercontent.com/${gituser}/${gitrepo}/${gitbranch}/config-v1.1.xml" > "${autoconfigpathfile}"

# Replace values with settings
fn_logecho "[INFO] Populating Thunderbird autoconfig file"
sed -i -e "s/HOSTNAME/${hostname}/g" "${autoconfigpathfile}"
sed -i -e "s/COMPANYURL/${companyurl}/g" "${autoconfigpathfile}"
sed -i -e "s/COMPANYNAME/${companyname}/g" "${autoconfigpathfile}"
sed -i -e "s/COMPANYSHORTNAME/${companyshortname}/g" "${autoconfigpathfile}"
sed -i -e "s@DOCURL@${docurl}@g" "${autoconfigpathfile}"

# DNS for autoconfig
fn_logecho "[INFO] Correcting default DNS zone for Thunderbird autoconfig: adding cname autoconfig to ${hostname}"
/usr/local/psa/bin/server_dns --add -cname autoconfig -canonical "${hostname}"

fn_logecho "[INFO] Adding DNS entry for every website for Thunderbird autoconfig: adding cname autoconfig to ${hostname}"
for i in `mysql -uadmin -p\`cat /etc/psa/.psa.shadow\` psa -Ns -e "select name from domains"`; do 
	/usr/local/psa/bin/dns --add "$i" -cname autoconfig -canonical "${hostname}"
done

## Outlook autodiscover
fn_logecho "[INFO] Writing Outlook autodiscover file"
curl "https://raw.githubusercontent.com/${gituser}/${gitrepo}/${gitbranch}/autodiscover.xml" > "${autodiscoverpathfile}"

# Outlook settings
fn_logecho "[INFO] Populating Outlook autodiscover file"
sed -i -e "s/HOSTNAME/${hostname}/g" "${autodiscoverpathfile}"
sed -i -e "s/COMPANYNAME/${companyname}/g" "${autodiscoverpathfile}"

## iOS config
fn_logecho "[INFO] Writing iOS config files"
curl "https://raw.githubusercontent.com/${gituser}/${gitrepo}/${gitbranch}/iphone.xml" > "${iphonepathfile}"
curl "https://raw.githubusercontent.com/${gituser}/${gitrepo}/${gitbranch}/iphone.mobileconfig" > "${iphonemobileconfpathfile}"

# iOS Logo
fn_logecho "[INFO] Downloading ${companyname} logo for iOS"
wget -O "${iospath}/${ioslogo}" "${ioslogourl}"
# iOS Settings
fn_logecho "[INFO] Populating iOS config files"
sed -i -e "s/IOSLOGO/${ioslogo}/g" "${iphonepathfile}"
sed -i -e "s/COMPANYNAME/${companyname}/g" "${iphonepathfile}"

sed -i -e "s/HOSTNAME/${hostname}/g" "${iphonemobileconfpathfile}"
sed -i -e "s/COMPANYNAME/${companyname}/g" "${iphonemobileconfpathfile}"
sed -i -e "s/COMPANYLOWERCASENAME/${companylowercasename}/g" "${iphonemobileconfpathfile}"

## .htaccess config
fn_logecho "[INFO] Writing htaccess file"
echo "AddHandler php-script .php .xml
RewriteEngine on
RewriteCond %{REQUEST_URI} !iphone.xml
RewriteCond %{REQUEST_URI} !${ioslogo}
RewriteCond %{REQUEST_URI} ios
RewriteRule .* /ios/iphone.xml [R]" > "${autodiscoverhtaccess}"

## HTTPD aliases config
fn_logecho "[INFO] Writing autodiscover httpd configuration file"
echo "Alias /mail \"${autoconfigpath}\"
Alias /autodiscover \"${autodiscoverpath}\"
Alias /Autodiscover \"${autodiscoverpath}\"
Alias /ios \"${iospath}\"" > "${httpdautodiscoverconf}"

fn_logecho "[INFO] Restarting httpd"
service httpd restart

## Testing

# Test Thunderbird autoconfig
if [ -n "$(curl "${autoconfigurl}" | grep "<socketType>SSL</socketType>")" ]; then
	fn_logecho "[OK] Thunderbird ${autoconfigurl} is accessible"
else
	fn_logecho "[ERROR!] Thunderbird ${autoconfigurl} does not seem to be accessible"
fi

# Test Outlook autodiscover
if [ -n "$(curl "${autodiscoverurl}" | grep "<DisplayName>${companyname}</DisplayName>")" ]; then
	fn_logecho "[OK] Outlook ${autodiscoverurl} is accessible"
else
	fn_logecho "[ERROR!] Outlook ${autodiscoverurl} does not seem to be accessible"
fi

# Test Outlook Autodiscover
if [ -n "$(curl "${autodiscoverurlalt}" | grep "<DisplayName>${companyname}</DisplayName>")" ]; then
	fn_logecho "[OK] Outlook ${autodiscoverurlalt} is accessible"
else
	fn_logecho "[ERROR!] Outlook ${autodiscoverurlalt} does not seem to be accessible"
fi

# Test Apple iOS configurator
if [ -n "$(curl "${iosconfigurl}" | grep "<form method=\"post\" action=\"iphone.xml\">")" ]; then
	fn_logecho "[OK] iOS ${iosconfigurl} is accessible"
else
	fn_logecho "[ERROR!] iOS ${iosconfigurl} does not seem to be accessible"
fi

fn_logecho "[INFO] Done"
