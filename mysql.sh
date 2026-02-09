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

dnf install mysql-server -y &>>$LOGS_FILE
VALIDATE $? "installing mysql......."
systemctl enable mysqld &>>$LOGS_FILE
VALIDATE $? "enabling mysql service...."
systemctl start mysqld &>>$LOGS_FILE
VALIDATE $? "starting mysql service"
mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOGS_FILE
VALIDATE $? "pass setup completed...."