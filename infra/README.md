# Manage Infra

This folder contains scripts for creating, starting, connecting to, and stopping AWS EC2 instances.

Before using these scripts, the [AWS CLI must be installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [authentication must be configured by running `aws configure`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html).

- `ec2_create.sh`: Create an EC2 instance.
- `ec2_start.sh`: Starts your EC2 instance.
- `ec2_connect.sh`: Connects you to EC2 via SSH.
- `ec2_stop.sh`: Stops your EC2 instance.
- `ec2_instance_install.sh`: Script to run on a new EC2 instance to install necessary system software (eg. Docker, CUDA, etc...)


### TODO:
- Add command line args to ec2_create.sh
- Create tag names to differentiate between dsenv instances in ec2_create.sh.
- Test creating multiple instances.
- Pass tag names into ec2_start/stop.sh scripts
- Pass tag names into ec2_connect scripts
