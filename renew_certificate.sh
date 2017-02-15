#!/bin/bash
set -e
export PATH=/opt/QPython2/bin:$PATH
export PATH=/opt/LetsEncrypt/bin:$PATH

function notify
{
    if $1; then
        /sbin/log_tool -a "$2" -t $3;
    fi
}

# VARIABLES, replace these with your own.
DOMAIN="www.example.com"
EMAIL="user@example.com"
WEBPATH="/share/Web/"
QTSNOTIFICATION=true
LOGFILE=""
###########################################
DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# do nothing if certificate is valid for more than 30 days (30*24*60*60)
echo "Checking whether to renew certificate on $(date -R)"
[ -s letsencrypt/live/$DOMAIN/cert.pem ] && openssl x509 -noout -in letsencrypt/live/$DOMAIN/cert.pem -checkend 2592000 && exit

echo "Running letsencrypt, Getting/Renewing certificate..."
(
        letsencrypt certonly --rsa-key-size 4096 --renew-by-default --webroot --webroot-path $WEBPATH -d $DOMAIN -t --agree-tos --email $EMAIL --config-dir $DIR/letsencrypt
)
if [ "$?" > 0 ];
then
    echo "...Error!"
    notify $QTSNOTIFICATION "[LetsEncrypt] Unable to renew certificate" 2
    exit 1
else
    echo "...Success!"
    notify $QTSNOTIFICATION "[LetsEncrypt] Certificate renewed with success" 0
fi

echo "Stopping stunnel and setting new stunnel certificates..."
/etc/init.d/stunnel.sh stop

cd letsencrypt/live/$DOMAIN
cat privkey.pem cert.pem > /etc/stunnel/stunnel.pem
cp chain.pem /etc/stunnel/uca.pem

echo "Done! Service startup and cleanup will follow now..."
/etc/init.d/stunnel.sh start
/etc/init.d/Qthttpd.sh restart
