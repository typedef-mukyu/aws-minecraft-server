#!/bin/bash
# Check for local machine prerequisites
echo "Checking dependencies..."
if ! which aws 2>&1 > /dev/null; then
    echo -e "\tAWS CLI: not found. Exiting..." >&2
    exit 1
else
    echo -e "\tAWS CLI: OK"
fi
if ! which terraform 2>&1 > /dev/null; then
    echo -e "\tTerraform: not found. Exiting..." >&2
    exit 1
else
    echo -e "\tTerraform: OK"
fi
# Generate SSH key pair
if [[ -e ~/.ssh/minecraftserver.pub ]]; then
    echo "Using existing public key."
elif ! ssh-keygen -q -f ~/.ssh/minecraftserver -P ""; then
    echo "Failed to create key pairs." >&2
    exit 1
fi
# Set up Terraform
export TF_VAR_ssh_public_key=$(cat ~/.ssh/minecraftserver.pub)
export TF_VAR_ec2_user_data_b64=$(./sfxshgen.sh ec2setup.sh ec2setup-mcsvc.sh minecraft.service | base64)
echo "Initializing Terraform..."
if ! terraform init -input=false > /dev/null; then
    echo "Terraform initialization failed." >&2
    exit 1
fi
echo "Creating AWS resources..."
if ! terraform apply -input=false -auto-approve; then
    echo "One or more AWS resources were not created successfully."
    exit 1
fi
echo "All AWS resources were created successfully."