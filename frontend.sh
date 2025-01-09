#!/bin/bash

# first $ is a command substitution, it allows to run a command and capture its output into a variable.
LOGS_FOLDER="/var/log/expense-shell"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)   
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USRID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m" # means no color

# idempotent
if [ $USRID -ne 0 ]
then
    echo "Please run the script with root user" | tee -a  $LOG_FILE
    exit 1
fi

echo -e "$G Script started executing at : $TIMESTAMP $N" | tee -a  $LOG_FILE

# THIS FUNCTION WILL BE UNTOUCHED UNLESS IT IS CALLED
VALIDATE() {
    if [ $1 -ne 0 ]
    then 
        echo -e "$2.. is $R failed.. $N" | tee -a  $LOG_FILE
        exit 1
    else 
        echo -e "$2.. is $G successful.. $N" | tee -a  $LOG_FILE
    fi
}

#  making it idempotent with if condition
dnf list installed nginx &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    echo -e "The nginx is not installed, $G we are going to install it, please wait.. $N" | tee -a  $LOG_FILE
    dnf install nginx -y &>>$LOG_FILE
    VALIDATE $? "Installing nginx" | tee -a  $LOG_FILE

    systemctl enable nginx &>>$LOG_FILE
    VALIDATE $? "Enabling nginx" | tee -a  $LOG_FILE

    systemctl start nginx &>>$LOG_FILE
    VALIDATE $? "Starting nginx" | tee -a  $LOG_FILE
    
else
    echo -e "$Y The nginx is already installed, nothing to do ... $N" | tee -a  $LOG_FILE
fi

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default website" | tee -a  $LOG_FILE

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend code" | tee -a  $LOG_FILE

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extracting frontend code" | tee -a  $LOG_FILE

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf &>>$LOG_FILE
VALIDATE $? "Copying expense configuration file" | tee -a $LOG_FILE

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting the nginx" | tee -a  $LOG_FILE

