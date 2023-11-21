# Manage Infra

This folder contains scripts for starting, connecting to, and stopping AWS EC2 instances.

Before using these scripts, you must manually create an EC2 instance through the AWS Console. Then, update the `config.ini` file with the instance id and public ip address of your instance.

- `ec2_start.sh`: Starts your EC2 instance.
- `ec2_connect.sh`: Connects you to EC2 via SSH.
- `ec2_stop.sh`: Stops your EC2 instance.
- `ec2_instance_install.sh`: Script to run on a new EC2 instance to install necessary system software (eg. Docker, CUDA, etc...)