#!/bin/bash

# Default variable values
REGION=us-east-1
TAG_PROJECT_NAME=dsenv
TAG_INSTANCE_NAME=micro
INSTANCE_TYPE=t3.micro
AMI=ami-0fc5d935ebf8bc3bc # This ami is Ubuntu Server 22.04 LTS. Pick a different ami at https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#AMICatalog:


# Parse flags/options
usage() {
 echo "Usage: $0 [OPTIONS] <COMMNAD>"
 echo "Options:"
 echo " -h, --help              Display this help message"
 echo " -r, --region            Specify which region to create your instances in"
 echo " -tp, --tag-project      Project name that will be set for all instances"
 echo " -ti, --tag-instance     Instance name that will be set for this specific instance"
 echo " -i, --instance-type     AWS EC2 instance type"
 echo " -a, --ami               AWS AMI to use during instance creation"
 echo "Commands:"
 echo " list                     List all available EC2 instances"
 echo " create                   Create an EC2 instance use default or supplied options"
 echo " start                    Start the specified EC2 instance"
 echo " stop                     Stop the specified EC2 instance" 
 echo " terminate                Stop the specified EC2 instance and delete it"

}

has_argument() {
    [[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

# Function to handle options and arguments
handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
      -h | --help)
        usage
        exit 0
        ;;
      -r | --region*)
        if ! has_argument $@; then
          echo "Region name not specified" >&2
          usage
          exit 1
        fi
        REGION=$(extract_argument $@)
        shift
        ;;
      -tp | --tag-project*)
        if ! has_argument $@; then
          echo "Project name not specified" >&2
          usage
          exit 1
        fi

        TAG_PROJECT_NAME=$(extract_argument $@)

        shift
        ;;
      -ti | --tag-instance*)
        if ! has_argument $@; then
          echo "Instance name not specified" >&2
          usage
          exit 1
        fi

        TAG_INSTANCE_NAME=$(extract_argument $@)

        shift
        ;;
      -i| --instance-type*)
        if ! has_argument $@; then
          echo "Instance type not specified" >&2
          usage
          exit 1
        fi

        INSTANCE_TYPE=$(extract_argument $@)

        shift
        ;;
      -a | --ami*)
        if ! has_argument $@; then
          echo "AMI not specified" >&2
          usage
          exit 1
        fi

        AMI=$(extract_argument $@)

        shift
        ;;
      list)
        ec2_list
        exit 0
        ;;
      create)
        ec2_create
        exit 0
        ;;
      start)
        ec2_start
        exit 0
        ;;
      stop)
        ec2_stop
        exit 0
        ;;
      terminate)
        ec2_terminate
        exit 0
        ;;
      *)
        echo "Invalid option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
  done
}


# Create a new EC2 instance
ec2_create() {
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
}


# Main script execution
handle_options "$@"

echo "REGION: $REGION"