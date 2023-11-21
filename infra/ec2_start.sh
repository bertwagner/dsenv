#!/bin/bash

source config.conf
aws ec2 start-instances --instance-ids $INSTANCE_ID
