#!/bin/bash

sudo chown -R $USER:ubuntu ~/.kube
source /etc/profile
sudo snap install microk8s --classic
# ubuntu as the user
sudo usermod -aG microk8s ubuntu

sudo snap install kubectl --classic
# no need if exit. 
sudo mkdir ~/.kube
# sudo chown -R $USER:ubuntu ~/.kube
sudo chown -f -R ubuntu ~/.kube
sudo microk8s config > ~/.kube/config
kubectl version --client

# Install protoc
sudo apt update
sudo apt install -y protobuf-compiler
protoc --version

# Install Go and build KEDA source code in the VM
echo "Installing Go and building KEDA source code inside the VM..."
# Navigate to the KEDA source code and build
cd /go/src/github.com/johnwayne19860314/keda
make build


# Check if the build was successful
if [ $? -ne 0 ]; then
  echo "Failed to build KEDA source code."
  exit 1
fi

echo "KEDA source code built successfully in the VM."