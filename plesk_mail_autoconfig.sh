#!/bin/bash
# Deploy mail autoconfig for Plesk
# Website: haisoft.fr

autoconfigpath="/var/www/vhosts/default/htdocs/mail"
autoconfigfile="config-v1.1.xml"
autoconfigpathfile="${autoconfigpath}/${autoconfigfile}"

echo "Mail autoconfig generator for Plesk"
echo "###################################"

if [ ! -d "${autoconfigpath}" ]; then
	echo "[INFO] Creating autoconfig path"
	mkdir -pv "${autoconfigpath}"
fi

if [ ! -f "${autoconfigpathfile}" ]; then
	echo "[INFO] Creating autoconfig file"
	touch "${autoconfigpathfile}"
fi

echo "[INFO] Writing into autoconfig file"

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>

<clientConfig version=\"1.1\">
  <emailProvider id=\"haisoft.net\">

    <domain>haisoft.net</domain>
    <displayName>HaiSoft</displayName>
    <displayShortName>HaiSoft</displayShortName>

    <incomingServer type=\"imap\">
      <hostname>$(hostname)</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <incomingServer type=\"imap\">
      <hostname>$(hostname)</hostname>
      <port>143</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <incomingServer type=\"pop3\">
      <hostname>$(hostname)</hostname>
      <port>995</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <incomingServer type=\"pop3\">
      <hostname>$(hostname)</hostname>
      <port>110</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>

    <outgoingServer type=\"smtp\">
      <hostname>$(hostname)</hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <outgoingServer type=\"smtp\">
      <hostname>$(hostname)</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <outgoingServer type=\"smtp\">
      <hostname>$(hostname)</hostname>
      <port>25</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-encrypted</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>

    <outgoingServer type=\"smtp\">
      <hostname>$(hostname)</hostname>
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

echo "[INFO] Correcting default DNS zone"
/usr/local/psa/bin/server_dns --add -cname autoconfig -canonical "$(hostname)"

echo "[INFO] Adding DNS entry for every website"

for i in `mysql -uadmin -p\`cat /etc/psa/.psa.shadow\` psa -Ns -e "select name from domains"`; do 
	/usr/local/psa/bin/dns --add "$i" -cname autoconfig -canonical "$(hostname)"
done

if [ -n "$(curl "http://autoconfig.$(hostname)/mail/config-v1.1.xml" | grep "<socketType>SSL</socketType>")" ]; then
	echo "[OK] http://autoconfig.$(hostname)/mail/config-v1.1.xml is accessible"
else
	echo "[ERROR!] http://autoconfig.$(hostname)/mail/config-v1.1.xml does not seem to be accessible"
fi

echo "[INFO] Done"
