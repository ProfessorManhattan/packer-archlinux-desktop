#!/usr/bin/env bash

PASSWORD=$(/usr/bin/openssl passwd -crypt 'vagrant')

# Vagrant-specific configuration
/usr/bin/useradd --password ${PASSWORD} --comment 'Vagrant User' --create-home --user-group vagrant
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' >/etc/sudoers.d/vagrant
echo "vagrant ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/vagrant
/usr/bin/chmod 0440 /etc/sudoers.d/vagrant
/usr/bin/systemctl start sshd.service
