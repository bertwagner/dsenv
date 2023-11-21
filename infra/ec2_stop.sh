#!/bin/bash

source config.ini
aws ec2 stop-instances --instance-ids $INSTANCE_ID
