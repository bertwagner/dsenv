SHELL := /bin/bash

start:
	source config
	aws ec2 start-instances --instance-ids $(INSTANCE_ID)

stop:
	source config
	aws ec2 stop-instances --instance-ids $(INSTANCE_ID)

connect:
	source config
	ssh -i ~/.ssh/dsenv.pem ubuntu@$(PUBLIC_IP)