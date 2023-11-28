#!/bin/bash

#Config variales
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

