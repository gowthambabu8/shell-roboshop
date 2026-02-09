#!/bin/bash

set -e #ERR

trap 'echo "There is error in line $LINENO, Command: $BASH_COMMAND"' ERR


USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-robo"
LOGS_FILE="/var/log/shell-robo/$0.log"
SCRIPT_DIR=$PWD
MYSQL_HOST="mysql.happielearning.com"
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

dnf install maven -y &>>$LOGS_FILE
USER_CHECK="roboshop"
if id "$USER_CHECK" &>/dev/null; then 
    echo -e "user roboshop already exists" | tee -a $LOGS_FILE
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
fi

mkdir -p /app &>>$LOGS_FILE
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOGS_FILE
VALIDATE $? "downloading shipping source code...."
cd /app &>>$LOGS_FILE

rm -rf /app/* 
unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "unzipping shipping source code...."

cd /app &>>$LOGS_FILE
mvn clean package &>>$LOGS_FILE
VALIDATE $? "clean and package...."
mv target/shipping-1.0.jar shipping.jar &>>$LOGS_FILE
VALIDATE $? "renaming of jar...."
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "mysql client installation...."
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Data loading..."
else
    echo -e "Data exists for cities database" | tee -a $LOGS_FILE
fi

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "daemon-reload...."
systemctl enable shipping &>>$LOGS_FILE
VALIDATE $? "enable shipping...."
systemctl start shipping &>>$LOGS_FILE
VALIDATE $? "start shipping...."
systemctl restart shipping &>>$LOGS_FILE
VALIDATE $? "restart shipping...."