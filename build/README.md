# OneBody Build Directory README

This directory is where we store configuration and provisioning scripts for installing and setting up OneBody in different environments.

## Contents

### packer.json

Packer.io config for creating various builds of OneBody, including OVF appliances for VirtualBox and VMWare (coming soon).

To build an OVF using VirtualBox, run the following

    packer build -only=virtualbox-iso packer.json

### ubuntu/14.04/provision.sh

This is the Bash script that installs all the necessary components for OneBody to run on Ubuntu server version 14.04.

It is designed to be run on a fresh install of Ubuntu server 14.04, but it may be helpful to you if you have an existing Ubuntu server instance running and wish to install OneBody on it.
