#!/bin/bash

source config
ssh -i ~/.ssh/dsenv.pem ubuntu@$PUBLIC_IP
