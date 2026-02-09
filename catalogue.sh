#!/bin/bash

set -e #ERR

trap 'echo "There is error in line $LINENO, Command: $BASH_COMMAND"' ERR


USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-robo"
LOGS_FILE="/var/log/shell-robo/$0.log"
SCRIPT_DIR=$PWD
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

dnf module list nodejs
dnf module disable nodejs -y
dnf module enable nodejs:20 -y
dnf install nodejs -y

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ];then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo -e "user roboshop already exists"
fi

mkdir -p /app
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip
cd /app

rm -rf /app/*
unzip /tmp/catalogue.zip
npm install

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue

