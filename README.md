# Let's Encrypt on QNAP : Adapted for TS-251 
Inspired by [Yannik's project](https://github.com/Yannik/qnap-letsencrypt) and http://banduccm.blogspot.co.uk/.

Use this to create an ssl certificate for your custom domain, so you can securely access your QNAP NAS from the internet.
Once that is done, you can create a cronjob to automatically renew the certificate before it expires.

## Install Instructions
### NAS Setup
1. Your NAS is expected to be on firmware 4.3.0 or later.
2. Login to your NAS and make sure Git is installed.
3. [ssh](https://wiki.qnap.com/wiki/How_to_SSH_into_your_QNAP_device) is also required.
4. Add the qnapclub.eu repo to the App Center. You can find the instructions [here](http://qnapclub.eu/index.php?act=howto)
5. Go into the new Qnapclub.eu repo, and install [LEgo](https://www.qnapclub.eu/fr/qpkg/456).
6. Make sure your NAS is reachable from the public internet under the domain you want to get a certificate for on port 80.
7. Create a folder to store qnap-letsencrypt in under `/share/YOUR_DRIVE/`. Do not create it directly in `/share/`, as it will be lost after a reboot!


### Setting up a valid ca-bundle and cloning this repo

By default, there is no ca-bundle (bundle of root certificates which we should trust)
installed. Therefore we will have to download one manually.

1. On your local pc with an intact certificate store, run
    ```
    curl -s https://curl.haxx.se/ca/cacert.pem | sha1sum
    ```

2. On your nas, in the directory you want to install qnap-letsencrypt in, run
    ```
    wget --no-check-certificate https://curl.haxx.se/ca/cacert.pem
    sha1sum cacert.pem
    ```

3. Compare the hashes obtained in step 1 and 2, they must match.

4. On your nas, in the directory you were in before
    ```
    git config --system http.sslVerify true
    git config --system http.sslCAinfo cacert.pem
    git clone https://github.com/szech/qnap-letsencrypt.git
    mv cacert.pem qnap-letsencrypt
    cd qnap-letsencrypt
    git config --system http.sslCAinfo cacert.pem
    ```

### Setting up qnap-letsencrypt
1. Edit `renew_certificate` and put your own values in the `VARIABLES` section   

2. Run `renew_certificate.sh`

3. Create a cronjob to run `renew_certificate.sh` every night, which will renew your certificate if it has less than 10 days left

    Add this to `/etc/config/crontab`:
    ```
    30 3 * * * cd /share/YOUR_INSTALL_LOCATION/qnap-letsencrypt/ && ./renew_certificate.sh >> ./renew_certificate.log 2>&1
    ```

    Then run:
    ```
    crontab /etc/config/crontab
    /etc/init.d/crond.sh restart
    ```

### FAQ

#### Why did you create this fork?
Got this script which is working perfectly. However I wanted more control and logs from it.

#### What's different to Szech's original script?
- Added error handler with hability to notify with QNAP internal system (Log & email)
- Replaced LetsEncrypt package (obsolete) by LEgo