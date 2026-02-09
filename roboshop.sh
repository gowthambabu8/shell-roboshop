#!/bin/bash

SG_ID="sg-038655dad535c0654"
AMI_ID="ami-0220d79f3f480ecf5"
INSTANCE_TYPE="t3.micro"
ZONE_ID="Z04536392HCJLZT52Z8K0"
PARENT_DOMAIN="happielearning.com"
for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text )

    echo "INSTANCE_ID :: $INSTANCE_ID"
    if [ $instance == "frontend" ]; then 
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text)
        DOMAIN_NAME=$PARENT_DOMAIN

    else
        IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[*].Instances[*].PrivateIpAddress" \
        --output text)
        DOMAIN_NAME="$instance.$PARENT_DOMAIN"
    fi

    echo "IP is $IP"
    echo "Domain is $DOMAIN"

    aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
        {
            "Comment": "Update A record to new IP",
            "Changes": [
                {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$DOMAIN_NAME'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [
                    { "Value": "'$IP'" }
                    ]
                }
                }
            ]
        }
        '
done