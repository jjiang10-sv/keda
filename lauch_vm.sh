#!/bin/bash


#microk8s config > ~/.kube/config
# sudo chown -R $USER ~/.kube
 # sudo chown -R $USER:ubuntu ~/.kube



# Set the KEDA source code directory (edit this to your own path)
KEDA_CODE_DIR="/Users/john/Documents/projects/aa/tutorials/scale/keda"

# Check if the KEDA_CODE_DIR exists
if [ ! -d "$KEDA_CODE_DIR" ]; then
  echo "The KEDA_CODE_DIR does not exist. Please check the path."
  exit 1
fi

echo "Launching Multipass VM with the KEDA source code mounted..."

# Launch the VM and mount the KEDA source code directory
multipass launch \
   --mount ${KEDA_CODE_DIR}:/go/src/github.com/johnwayne19860314/keda \
   --name keda-dev --cpus 2 --mem 4G --disk 40G

# Check if the VM launched successfully
if [ $? -ne 0 ]; then
  echo "Failed to launch the Multipass VM."
  exit 1
fi

echo "VM keda-dev launched successfully."

# Install Go and build KEDA source code in the VM
echo "Installing Go and building KEDA source code inside the VM..."

multipass exec keda-dev -- bash -c "
  #sudo su
  apt-get update
  apt-get install -y build-essential make wget
  wget https://go.dev/dl/go1.21.13.linux-arm64.tar.gz
  tar -C /usr/local -zxvf go1.21.13.linux-arm64.tar.gz
  rm go1.21.13.linux-arm64.tar.gz

  # Add Go to PATH
  echo 'export PATH=\$PATH:/usr/local/go/bin' >> /etc/profile
  echo 'export GOROOT=/usr/local/go' >> /etc/profile
  source /etc/profile

  # Check Go installation
  go version

  # Set Go proxy (optional)
  # go env -w GOPROXY=https://goproxy.cn,direct

  sudo snap install microk8s --classic
  sudo usermod -aG microk8s $USER
  sudo chown -f -R $USER ~/.kube
  snap install kubectl --classic
  kubectl version --client
  microk8s config > ~/.kube/config



  # Navigate to the KEDA source code and build
  cd /go/src/github.com/johnwayne19860314/keda
  make build
"

# Check if the build was successful
if [ $? -ne 0 ]; then
  echo "Failed to build KEDA source code."
  exit 1
fi

echo "KEDA source code built successfully in the VM."
