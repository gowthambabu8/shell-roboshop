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

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGS_FILE
VALIDATE $? "copying mongo repo..."

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "installing mongodb package...."

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "enabling mongod service..."

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "starting mongod service..."

sed 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOGS_FILE

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "restarting mongod service..."