#!/bin/bash

#Config variables
REGION=us-east-1
TAG_PROJECT_NAME=dsenv
INSTANCE_TYPE=t3.micro
AMI=ami-0fc5d935ebf8bc3bc # This ami is Ubuntu Server 22.04 LTS. Pick a different ami at https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#AMICatalog:

echo "Setting up instance in $REGION with name $TAG_PROJECT_NAME"


# Check if VPC exists
VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=tag:Project,Values=$TAG_PROJECT_NAME \
    --query 'Vpcs[*].VpcId' \
    --output text)

if [[ "$VPC_ID" == "" ]]
then
    # Create the VPC
    echo "dsenv VPC doesn't exist. Creating..."
    VPC_ID=$(aws ec2 create-vpc \
        --cidr-block 10.0.0.0/24 \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Project,Value=$TAG_PROJECT_NAME},{Key=Name,Value=$TAG_PROJECT_NAME}]" \
        --query Vpc.VpcId \
        --output text)
fi

echo "Using VPC with ID: $VPC_ID"


# Check if subnet exists
SUBNET_ID=$(aws ec2 describe-subnets \
    --filters Name=tag:Project,Values=$TAG_PROJECT_NAME \
    --query 'Subnets[*].SubnetId' \
    --output text)

if [[ "$SUBNET_ID" == "" ]]
then
    # Create the subnet
    echo "dsenv subnet doesn't exist. Creating..."
    SUBNET_ID=$(aws ec2 create-subnet \
        --vpc-id $VPC_ID \
        --cidr-block 10.0.0.0/24 \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Project,Value=$TAG_PROJECT_NAME},{Key=Name,Value=$TAG_PROJECT_NAME}]" \
        --query Subnets.SubnetId \
        --output text)
fi
echo "Using subnet with ID: $SUBNET_ID"

# Check if the key pair exists. If it does, we assume it is already in ~/.ssh
KEY_NAME=$(aws ec2 describe-key-pairs \
    --filters Name=key-name,Values=$TAG_PROJECT_NAME \
    --query "KeyPairs[*].KeyName" \
    --output text)

if [[ "$KEY_NAME" == "" ]]
then
    echo "dsenv key pair doesn't exist. Creating..."
    aws ec2 create-key-pair \
        --key-name "$TAG_PROJECT_NAME" \
        --tag-specification "ResourceType=key-pair,Tags=[{Key=Name,Value=$TAG_PROJECT_NAME},{Key=Project,Value=$TAG_PROJECT_NAME}]" \
        --query "KeyMaterial" \
        --output text > ~/".ssh/$TAG_PROJECT_NAME.pem"
fi
echo "Using keypair with name: $KEY_NAME"


# Check if the security group exists
GROUP_ID=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values=$TAG_PROJECT_NAME \
    --query "SecurityGroups[*].GroupId" \
    --output text)

# Create security group 
if [[ "$GROUP_ID" == "" ]]
then
    echo "dsenv security group doesn't exist. Creating..."
    GROUP_ID=$(aws ec2 create-security-group \
        --group-name $TAG_PROJECT_NAME \
        --tag-specification "ResourceType=security-group,Tags=[{Key=Name,Value=$TAG_PROJECT_NAME},{Key=Project,Value=$TAG_PROJECT_NAME}]" \
        --description "dsenv default group created from cli" \
        --vpc-id $VPC_ID \
        --query "GroupId" \
        --output text)
fi

echo "Using security group with ID: $GROUP_ID"

# Add inbound rules to security group. Supress errors if it already exists
aws ec2 authorize-security-group-ingress \
    --group-id $GROUP_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --output text &>/dev/null

# Check if the instance exists
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters Name=tag:Project,Values=$TAG_PROJECT_NAME \
    --query 'Reservations[*].Instances[?!contains(State.Name, `terminated`)].InstanceId' \
    --output text)

if [[ "$INSTANCE_ID" == "" ]]
then
    # Create the instance. 
    echo "Creating instance..."
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI \
        --instance-type $INSTANCE_TYPE \
        --count 1 \
        --key-name $KEY_NAME \
        --subnet-id $SUBNET_ID \
        --security-group-ids $GROUP_ID \
        --tag-specification "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_PROJECT_NAME},{Key=Project,Value=$TAG_PROJECT_NAME}]" \
        --query Instances[*].InstanceId \
        --output text)
fi
echo "Using instance with ID: $INSTANCE_ID"


# Get the availability zone of the instance
AVAILABILITY_ZONE=$(aws ec2 describe-instances \
    --filters Name=tag:Project,Values=$TAG_PROJECT_NAME \
    --query 'Reservations[*].Instances[?!contains(State.Name, `terminated`)].Placement.AvailabilityZone' \
    --output text)

echo "Instance in availability zone: $AVAILABILITY_ZONE"


# Check if the volume exists
VOLUME_ID=$(aws ec2 describe-volumes \
    --filters Name=tag:Project,Values=$TAG_PROJECT_NAME \
    --query "Volumes[*].VolumeId" \
    --output text)

if [[ "$VOLUME_ID" == "" ]]
then
    # Create a volume
    echo "Creating volume..."
    VOLUME_ID=$(aws ec2 create-volume \
        --availability-zone $AVAILABILITY_ZONE \
        --size 30 \
        --volume-type gp3 \
        --tag-specification "ResourceType=volume,Tags=[{Key=Name,Value=$TAG_PROJECT_NAME},{Key=Project,Value=$TAG_PROJECT_NAME}]" \
        --query "VolumeId" \
        --output text)
fi
echo "Using volume with ID: $VOLUME_ID"

# Attach the volume
ATTACHED=$(aws ec2 attach-volume --device /dev/sdh --instance-id $INSTANCE_ID --volume-id $VOLUME_ID --output text)

echo "Congratulations, your instance is ready!"