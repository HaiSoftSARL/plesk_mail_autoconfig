#!/bin/bash
# Deploy mail autoconfig for Plesk
# Website: haisoft.fr

# Autoconfig paths
autoconfigpath="/var/www/vhosts/default/htdocs/mail"
autoconfigfile="config-v1.1.xml"
autoconfigpathfile="${autoconfigpath}/${autoconfigfile}"

# Autodiscover paths
autodiscoverpath="/var/www/vhosts/default/htdocs/autodiscover"
autodiscoverpathfile="${autodiscoverpath}/autodiscover.xml"
autodiscoverhtaccess="${autodiscoverpath}/.htaccess"
autodiscoverconffile="/etc/httpd/conf.d/autodiscover.conf"

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


echo "Mail autoconfig && autodiscover generator for Plesk"
echo "###################################"

if [ ! -d "${autoconfigpath}" ]; then
	fn_logecho "[INFO] Creating autoconfig cofngi path"
	mkdir -pv "${autoconfigpath}"
fi

if [ ! -f "${autoconfigpathfile}" ]; then
	fn_logecho "[INFO] Creating autoconfig config file"
	touch "${autoconfigpathfile}"
fi

if [ ! -d "${autodiscoverpath}" ]; then
	fn_logecho "[INFO] Creating autodiscover config path"
	mkdir -pv "${autodiscoverpath}"
fi

if [ ! -f "${autodiscoverpathfile}" ]; then
	fn_logecho "[INFO] Creating autodiscover config file"
	touch "${autodiscoverpathfile}"
fi

if [ ! -f "${autodiscoverhtaccess}" ]; then
	fn_logecho "[INFO] Creating autodiscover .htaccess file"
	touch "${autodiscoverhtaccess}"
fi

if [ ! -f "${autodiscoverhtaccess}" ]; then
	fn_logecho "[INFO] Creating autodiscover .htaccess file"
	touch "${autodiscoverhtaccess}"
fi

if [ ! -f "${autodiscoverconffile}" ]; then
	fn_logecho "[INFO] Creating autodiscover httpd configuration file"
	touch "${autodiscoverconffile}"
fi

fn_logecho "[INFO] Writing autoconfig config file"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<clientConfig version=\"1.1\">
  <emailProvider id=\"haisoft.net\">

    <domain>haisoft.net</domain>
    <displayName>HaiSoft</displayName>
    <displayShortName>HaiSoft</displayShortName>

    <incomingServer type=\"imap\">
      <hostname>${hostname}</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <incomingServer type=\"imap\">
      <hostname>${hostname}</hostname>
      <port>143</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <incomingServer type=\"pop3\">
      <hostname>${hostname}</hostname>
      <port>995</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <incomingServer type=\"pop3\">
      <hostname>${hostname}</hostname>
      <port>110</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <outgoingServer type=\"smtp\">
      <hostname>${hostname}</hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <outgoingServer type=\"smtp\">
      <hostname>${hostname}</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <outgoingServer type=\"smtp\">
      <hostname>${hostname}</hostname>
      <port>25</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <outgoingServer type=\"smtp\">
      <hostname>${hostname}</hostname>
      <port>2525</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <documentation url=\"http://help.haisoft.net/\">
      <descr lang=\"fr\">Documentation</descr>
      <descr lang=\"en\">Documentation</descr>
    </documentation>

  </emailProvider>
</clientConfig>" > "${autoconfigpathfile}"

fn_logecho "[INFO] Correcting default DNS zone for autoconfig"
/usr/local/psa/bin/server_dns --add -cname autoconfig -canonical "${hostname}"

fn_logecho "[INFO] Adding DNS entry for every website for autoconfig"

for i in `mysql -uadmin -p\`cat /etc/psa/.psa.shadow\` psa -Ns -e "select name from domains"`; do 
	/usr/local/psa/bin/dns --add "$i" -cname autoconfig -canonical "${hostname}"
done

fn_logecho "[INFO] Writing autodiscover config file"
echo "<?php
\$raw = file_get_contents('php://input');
\$matches = array();
preg_match('/<EMailAddress>(.*)<\/EMailAddress>/', \$raw, \$matches);
header('Content-Type: application/xml');
?>
<Autodiscover xmlns=\"http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006\">
  <Response xmlns=\"http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a\">
    <User>
      <DisplayName>HaiSoft</DisplayName>
    </User>
    <Account>
      <AccountType>email</AccountType>
      <Action>settings</Action>
      <Protocol>
        <Type>IMAP</Type>
        <Server>${hostname}</Server>
        <Port>993</Port>
        <DomainRequired>off</DomainRequired>
        <SPA>off</SPA>
        <SSL>on</SSL>
        <AuthRequired>on</AuthRequired>
        <LoginName><?php echo \$matches[1]; ?></LoginName>
      </Protocol>
      <Protocol>
        <Type>SMTP</Type>
        <Server>${hostname}</Server>
        <Port>465</Port>
        <DomainRequired>off</DomainRequired>
        <SPA>off</SPA>
        <SSL>on</SSL>
        <AuthRequired>on</AuthRequired>
        <LoginName><?php echo \$matches[1]; ?></LoginName>
      </Protocol>
    </Account>
  </Response>
</Autodiscover>" > "${autodiscoverpathfile}"

fn_logecho "[INFO] Writing autodiscover htaccess"
echo "AddHandler php-script .php .xml" > "${autodiscoverhtaccess}"

fn_logecho "[INFO] Writing autodiscover httpd configuration file"
echo "Alias /autodiscover \"/var/www/vhosts/default/htdocs/autodiscover\"" > "${autodiscoverconffile}"
fn_logecho "[INFO] Restarting httpd"
service httpd restart

if [ -n "$(curl "http://autoconfig.${hostname}/mail/config-v1.1.xml" | grep "<socketType>SSL</socketType>")" ]; then
	fn_logecho "[OK] http://autoconfig.${hostname}/mail/config-v1.1.xml is accessible"
else
	fn_logecho "[ERROR!] http://autoconfig.${hostname}/mail/config-v1.1.xml does not seem to be accessible"
fi

if [ -n "$(curl "https://${hostname}/autodiscover/autodiscover.xml" | grep "<DisplayName>HaiSoft</DisplayName>")" ]; then
	fn_logecho "[OK] https://${hostname}/autodiscover/autodiscover.xml is accessible"
else
	fn_logecho "[ERROR!] https://${hostname}/autodiscover/autodiscover.xml does not seem to be accessible"
fi

fn_logecho "[INFO] Done"
