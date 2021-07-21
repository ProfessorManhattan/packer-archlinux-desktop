#!/usr/bin/env bash

PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')

# Vagrant-specific configuration
<<<<<<< HEAD
/usr/bin/useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
=======
/usr/bin/useradd --password "${PASSWORD}" --comment 'Vagrant User' --create-home --user-group vagrant
>>>>>>> a8fc7639307ca74cce20e1deda9c9ed84422d37e
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' >/etc/sudoers.d/vagrant
echo "vagrant ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/vagrant
/usr/bin/chmod 0440 /etc/sudoers.d/vagrant
/usr/bin/systemctl start sshd.service
