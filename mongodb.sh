#!/bin/bash

set -e #ERR

trap 'echo "There is error in line $LINENO, Command: $BASH_COMMAND"' ERR


USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-robo"
LOGS_FILE="/var/log/shell-robo/$0.log"

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]; then 
    echo "Please use super user to install" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo "$2.... FAILED" | tee -a $LOGS_FILE
        exit 1
    else
        echo "$2.... SUCCESS" | tee -a $LOGS_FILE
fi    
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo repo..."

dnf install mongodb-org -y
VALIDATE $? "installing mongodb package...."

systemctl enable mongod
VALIDATE $? "enabling mongod service..."

systemctl start mongod
VALIDATE $? "starting mongod service..."

sed 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod
VALIDATE $? "restarting mongod service..."