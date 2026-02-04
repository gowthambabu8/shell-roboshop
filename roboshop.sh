#!/bin/bash

SG_ID="sg-038655dad535c0654"
AMI_ID="ami-0220d79f3f480ecf5"
INSTANCE_TYPE="t3.micro"
for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]")

    echo "INSTANCE_ID :: $INSTANCE_ID"
    if [ $instance == "frontend" ]; then 
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text)
    else
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[*].Instances[*].PrivateIpAddress" \
        --output text)
    fi

    echo "IP is $IP"
done