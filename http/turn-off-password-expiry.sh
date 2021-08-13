#!/usr/bin/env bash
echo '==> Turning off password expiry'
sudo sed -i '/password   include      system-local-login/c\#password   include      system-local-login' /etc/pam.d/login
PASSWD=$(echo "vagrant"|openssl passwd -6 -stdin)
sudo sed -i "/root.*\:$/c\root:$PASSWD:::::::" /etc/shadow
PASSWD=$(echo "vagrant"|openssl passwd -6 -stdin)
sudo sed -i "/vagrant.*\:$/c\vagrant:$PASSWD:::::::" /etc/shadow
