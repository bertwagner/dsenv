#!/bin/bash

source config
aws ec2 start-instances --instance-ids $INSTANCE_ID
