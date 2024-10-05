#!/bin/bash

sudo su
apt-get update 
apt-get install -y build-essential make wget 
wget https://go.dev/dl/go1.21.13.linux-arm64.tar.gz 
tar -C /usr/local -zxvf go1.21.13.linux-arm64.tar.gz 
rm go1.21.13.linux-arm64.tar.gz \

# Add Go to PATH
echo 'export GOROOT=/usr/local/go' >> /etc/profile
echo 'export PATH=\$PATH:/bin:/usr/bin:/snap/bin:/usr/local/go/bin' >> /etc/profile 
source /etc/profile

# Check Go installation
go version

#Set Go proxy (optional)
#go env -w GOPROXY=https://goproxy.cn,direct
