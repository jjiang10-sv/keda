#!/bin/bash

# Set the KEDA source code directory (edit this to your own path)
KEDA_CODE_DIR="/Users/john/Documents/projects/aa/tutorials/scale/keda"

# Check if the KEDA_CODE_DIR exists
if [ ! -d "$KEDA_CODE_DIR" ]; then
  echo "The KEDA_CODE_DIR does not exist. Please check the path."
  exit 1
fi

echo "Launching Multipass VM with the KEDA source code mounted..."

# multipass launch  ubuntu:20.04 --mount /Users/john/Documents/docs/nyit/labs:/go/src/nyit/labs  --name nyit-lab --cpus 2 --mem 4G --disk 40G
# Unmount the existing mount (if needed)
# multipass umount keda-dev
# # Mount the new directory
# multipass mount /Users/john/Documents/docs/nyit/labs nyit-lab:/home/ubuntu/nyit/labs
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


