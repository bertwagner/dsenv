#!/bin/bash

source config.ini
ssh -i ~/.ssh/dsenv.pem ubuntu@$PUBLIC_IP
