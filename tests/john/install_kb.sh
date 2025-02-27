# Download kubebuilder (replace <version> with the desired version)
KUBEBUILDER_VERSION=2.3.2 # Example version
curl -L https://go.kubebuilder.io/dl/${KUBEBUILDER_VERSION}/$(uname -s)/$(uname -m) | tar -xz -C /tmp/

# Move kubebuilder to a directory in your PATH
sudo mv /tmp/kubebuilder_${KUBEBUILDER_VERSION} /usr/local/kubebuilder