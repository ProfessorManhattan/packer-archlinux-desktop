# Archlinux Vagrant Box (Built with Packer)

This repository contains the files necessary to:

1. Build Archlinux via Packer
2. Set up networking and add the default Vagrant public key to the `vagrant` user's `.ssh` folder
3. Export a `.box` file which can be used with Vagrant

## Building the Box

Run the following command to build a `.box` file that Vagrant can use:

```
packer validate template.json
packer build template.json
```
