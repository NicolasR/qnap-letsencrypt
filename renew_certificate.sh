#!/bin/bash
set -e
export PATH=/opt/LEgo/bin:$PATH
PATH="$PATH:/usr/bin:/usr/sbin"

# VARIABLES, replace these with your own.
DOMAIN="domain"
EMAIL="email"
WEBPATH="/share/Web/"
QTSNOTIFICATION=true
LOGFILE=""
DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DAYSEXPIRATION=15

# FUNCTIONS
function notify
{
    if [ $QTSNOTIFICATION = true ]
    then
        /sbin/log_tool -a "$1" -t $2
    fi
}

###########################################
echo DOMAIN = $DOMAIN
echo EMAIL = $EMAIL
echo DIR = $DIR

WORKDIR="$DIR/LEgo"
CERTIFICATENAME="$DOMAIN.pem"
CERTIFICATESDIR="$WORKDIR/certificates"

# do nothing if certificate is valid for more than 30 days (30*24*60*60)
echo "Checking whether to renew certificate on next $DAYSEXPIRATION days"
[ -s "$CERTIFICATESDIR/$CERTIFICATENAME" ] && openssl x509 -in "$CERTIFICATESDIR/$CERTIFICATENAME" -checkend $(( 86400 * $DAYSEXPIRATION )) && exit

echo "Running letsencrypt, Getting/Renewing certificate..."
(
  lego --accept-tos --pem --key-type rsa2048 --http --http.webroot $WEBPATH --domains $DOMAIN --email $EMAIL --path $WORKDIR run
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

echo "live directory = $WORKDIR"
cd "$CERTIFICATESDIR"
cp /etc/stunnel/stunnel.pem /etc/stunnel/stunnel.pem.old
cp "$CERTIFICATENAME" /etc/stunnel/stunnel.pem

if [ ! -s /etc/stunnel/stunnel.pem ]
then
  echo "Error occured, restoring files"
  cp -rf /etc/stunnel/stunnel.pem.old /etc/stunnel/stunnel.pem
fi

echo "Done! Service startup and cleanup will follow now..."
/etc/init.d/stunnel.sh start
/etc/init.d/Qthttpd.sh restart
