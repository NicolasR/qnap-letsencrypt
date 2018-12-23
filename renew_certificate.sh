#!/bin/bash
set -e
export PATH=/opt/QPython3/bin:$PATH
export PATH=/opt/LetsEncrypt/bin:$PATH
PATH="$PATH:/usr/bin:/usr/sbin"

# VARIABLES, replace these with your own.
DOMAIN=""
DOMAINDIR=""
EMAIL=""
WEBPATH="/share/Web/"
QTSNOTIFICATION=true
LOGFILE=""
DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# FUNCTIONS
function notify
{
    if [ $QTSNOTIFICATION = true ]
    then
        /sbin/log_tool -a "$1" -t $2
    fi
}

###########################################
mkdir -p "$DOMAINDIR"

# do nothing if certificate is valid for more than 30 days (30*24*60*60)
echo "Checking whether to renew certificate on $(date -R)"
[ -s "$DOMAINDIR/cert.pem" ] && openssl x509 -in "$DOMAINDIR/cert.pem" -checkend 864000 && exit

echo "Running letsencrypt, Getting/Renewing certificate..."
(
     certbot certonly --rsa-key-size 4096 --renew-by-default --webroot --webroot-path $WEBPATH -d $DOMAIN -t --agree-tos --email $EMAIL --config-dir $DIR/letsencrypt
)

if [ "$?" -ne 0 ];
then
    echo "...Error!"
    notify "[LetsEncrypt] Unable to renew certificate" 2
    exit 1
else
    echo "...Success!"
    notify "[LetsEncrypt] Certificate renewed with success" 0
fi


echo "Stopping stunnel and setting new stunnel certificates..."
/etc/init.d/stunnel.sh stop

echo "live directory = $DOMAINDIR"
cd "$DOMAINDIR"
cp /etc/stunnel/stunnel.pem /etc/stunnel/stunnel.pem.old
cp /etc/stunnel/uca.pem /etc/stunnel/uca.pem.old
cat privkey.pem cert.pem > /etc/stunnel/stunnel.pem
cp chain.pem /etc/stunnel/uca.pem
if [ ! -s /etc/stunnel/stunnel.pem ]
then
  echo "Error occured, restoring files"
  cp -rf /etc/stunnel/stunnel.pem.old /etc/stunnel/stunnel.pem
  cp -rf /etc/stunnel/uca.pem.old /etc/stunnel/uca.pem
fi

echo "Done! Service startup and cleanup will follow now..."
/etc/init.d/stunnel.sh start
/etc/init.d/Qthttpd.sh restart
