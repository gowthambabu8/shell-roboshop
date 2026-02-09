#!/bin/bash

set -e #ERR

trap 'echo "There is error in line $LINENO, Command: $BASH_COMMAND"' ERR


USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-robo"
LOGS_FILE="/var/log/shell-robo/$0.log"
SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.happielearning.com"
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

dnf module disable redis -y &>>$LOGS_FILE
VALIDATE $? "disabling latest module redis..."
dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "enabling module 7 for redis...."
dnf install redis -y &>>$LOGS_FILE
VALIDATE $? "installing redis...."
sed -i -e "s/127.0.0.1/0.0.0.0/g" -e "/protected-mode/c protected-mode no" /etc/redis/redis.conf
systemctl enable redis &>>$LOGS_FILE
VALIDATE $? "enabling redis service..."
systemctl start redis &>>$LOGS_FILE
VALIDATE "starting redis service...."
