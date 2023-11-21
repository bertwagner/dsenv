#!/bin/bash

source config.conf
ssh -i ~/.ssh/dsenv.pem ubuntu@$PUBLIC_IP
