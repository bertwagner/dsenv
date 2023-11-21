#!/bin/bash

source config.conf
aws ec2 stop-instances --instance-ids $INSTANCE_ID
