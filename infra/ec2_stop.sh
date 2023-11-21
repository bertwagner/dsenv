#!/bin/bash

source config
aws ec2 stop-instances --instance-ids $INSTANCE_ID
