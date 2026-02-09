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

dnf module list nodejs &>>$LOGS_FILE
VALIDATE $? "listing nodejs modules...."
dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "disabling latest nodejs module...."
dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "enabling version 20 for nodejs...."
dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "installing nodejs required version...."

USER_CHECK="roboshop"
if id "$USER_CHECK" &>/dev/null; then 
    echo -e "user roboshop already exists" | tee -a $LOGS_FILE
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
fi

mkdir -p /app &>>$LOGS_FILE
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading catalogue source code...."
cd /app &>>$LOGS_FILE

rm -rf /app/* 
unzip /tmp/catalogue.zip
VALIDATE $? "unzipping catalogue source code...."
npm install
VALIDATE $? "installing npm build tool...."
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "thread daemon reload...."
systemctl enable catalogue &>>$LOGS_FILE
VALIDATE $? "enabling catalogue service...."
systemctl start catalogue &>>$LOGS_FILE
VALIDATE $? "starting catalogue service..."
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "installing mongodb client...."
mongosh --host $MONGODB_HOST </app/db/master-data.js
VALIDATE $? "data loading completed...."
