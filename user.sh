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
curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading user source code...."
cd /app &>>$LOGS_FILE

rm -rf /app/* 
unzip /tmp/user.zip
VALIDATE $? "unzipping user source code...."
npm install
VALIDATE $? "installing npm build tool...."
cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "thread daemon reload...."
systemctl enable user &>>$LOGS_FILE
VALIDATE $? "enabling user service...."
systemctl start user &>>$LOGS_FILE
VALIDATE $? "starting user service..."