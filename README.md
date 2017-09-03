# plesk_mail_autoconfig

Deploys Plesk autoconfig functionnality for:

- Thunderbird autoconfig
- Outlook autodiscover
- Apples iOS config generator

## Usage

1) Download & make executable

````bash
wget https://raw.githubusercontent.com/UltimateByte/plesk_mail_autoconfig/master/plesk_mail_autoconfig.sh && chmod +x plesk_mail_autoconfig.sh
````

2) Configure

````bash
nano plesk_mail_autoconfig.sh
````

3) Run

````bash
./plesk_mail_autoconfig.sh
````

## Requirements
- Your Plesk default domain must be set to "None" (default).
- This script assumes that your machine hostname is the one to connect to for mail, and that it has SSL/TLS certificates (best practice).
- Your DNS zones shall preferably be managed into Plesk, otherwise, for Thunderbird autoconfig to work, you just need to add the following CNAME to your domain names' DNS zones: autoconfig > [hostname].tld.
- HTTPS access is required for Outlook (with a signed certificate for each domain).

## What this script does
- Creates a "mail/" directory into your default Plesk hosting page.
- Adds /ios, /autodiscover and /Autodiscover aliases that point to the mail/ dir, for iOS and Outlook.
- Accordingly to the configuration, adds the required .xml configuration files into mail/.
- Adds a CNAME to all your domains for Thunderbird autoconfig : autoconfig > [hostname].tld. (If your DNS zone is not managed into Plesk, make sure to add this entry into it.) This domain must not actually exist in your Plesk, in order to be redirected to the default hosting.
- Changes the default DNS zone to add the autoconfig cname.

## Limitations
- Android doesn't seem to have any kind of mail autoconfiguration at the moment.
- The "Mail" program form Mac OSX doesn't seem to have any kind of mail autoconfiguration at the moment.
- You shall not use /ios or /autodiscover for your websites, because they are reserved for mail configuraiton.

### Notes
 If you need different settings for emails (ports, protocols, etc.), feel free to fork this, and change the repo (gituser, gitrepo, and gitbranch) to yours.
 
 # Credits
 From the Company HaiSoft https://www.haisoft.fr/
Benoît Ouacham: https://benoua.fr/
Robin Labadie: https://www.lrob.fr/
