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

dnf install python3 gcc python3-devel -y &>>$LOGS_FILE

USER_CHECK="roboshop"
if id "$USER_CHECK" &>/dev/null; then 
    echo -e "user roboshop already exists" | tee -a $LOGS_FILE
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
fi

mkdir -p /app &>>$LOGS_FILE
curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading payment source code...."
cd /app &>>$LOGS_FILE
pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "downloading payment required packages...."
cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE
systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "daemon reload...."
systemctl enable payment &>>$LOGS_FILE
VALIDATE $? "enabling payment...."
systemctl start payment &>>$LOGS_FILE
VALIDATE $? "starting payment...."