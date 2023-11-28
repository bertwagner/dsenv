#!/bin/bash

#Config variables
REGION=us-east-1
TAG_PROJECT_NAME=dsenv



# Check if VPC exists
VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=tag:Project,Values=$TAG_PROJECT_NAME \
    --query 'Vpcs[*].VpcId' \
    --output text)

if [[ "$VPC_ID" == "" ]]
then
    # Create the VPC
    VPC_ID=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/24 \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Project,Value=$TAG_PROJECT_NAME},{Key=Name,Value=$TAG_PROJECT_NAME}]" \
        --query Vpc.VpcId \
        --output text)
fi




# Check if the key pair exists. If it does, we assume it is already in ~/.ssh
KEY_NAME=$(aws ec2 describe-key-pairs \
    --filters Name=key-name,Values=$TAG_PROJECT_NAME \
    --query "KeyPairs[*].KeyName" \
    --output text)

if [[ "$KEY_NAME" == "" ]]
then
    echo "Creating keypair"
    aws ec2 create-key-pair \
        --key-name "$TAG_PROJECT_NAME" \
        --tag-specification "ResourceType=key-pair,Tags=[{Key=Name,Value=$TAG_PROJECT_NAME},{Key=Project,Value=$TAG_PROJECT_NAME}]" \
        --query "KeyMaterial" \
        --output text > ~/".ssh/$TAG_PROJECT_NAME.pem"
fi

