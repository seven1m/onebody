# OneBody Build Directory README

This directory is where we store configuration and provisioning scripts for installing and setting up OneBody in different environments.

## Contents

### packer.json

Packer.io config for creating various builds of OneBody, including OVF appliances for VirtualBox and VMWare.

### ubuntu/14.04/provision.sh

This is the Bash script that installs all the necessary components for OneBody to run on Ubuntu server version 14.04.

It is designed to be run on a fresh install of Ubuntu server 14.04, but it may be helpful to you if you have an existing Ubuntu server instance running and wish to install OneBody on it.

### ubuntu/16.04/provision.sh

Same as above, but for Ubuntu 16.04.

## Building

### VirtualBox

To build an OVF using VirtualBox, run the following:

    packer build -only=virtualbox-iso packer.json


### Amazon AMI

To build an AMI on Amazon AWS, run the following:

    AWS_ACCESS_KEY=your-access-key AWS_SECRET_KEY=your-access-secret packer build -debug -only=amazon-ebs packer.json

(Replace `your-access-key` and `your-access-secret` with your AWS access info.)
