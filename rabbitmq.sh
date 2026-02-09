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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOGS_FILE
VALIDATE $? "copying rabbitmq repo..."
dnf install rabbitmq-server -y &>>$LOGS_FILE
VALIDATE $? "installing rabbitmq..."
systemctl enable rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "enabling rabbitmq..."
systemctl start rabbitmq-server &>>$LOGS_FILE
VALIDATE $? "starting rabbitmq..."
rabbitmqctl add_user roboshop roboshop123 &>>$LOGS_FILE
VALIDATE $? "adding user..."
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOGS_FILE
VALIDATE $? "setting permission..."