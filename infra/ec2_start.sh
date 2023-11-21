#!/bin/bash

source config.ini
aws ec2 start-instances --instance-ids $INSTANCE_ID
