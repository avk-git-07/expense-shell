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
dnf list installed nodejs &>>$LOG_FILE
if [ $? -ne 0 ]
then 
    echo "The nodejs is not installed, we are going to install it.." | tee -a  $LOG_FILE
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Disabling nodejs current version" | tee -a  $LOG_FILE

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enabling nodejs:20 version" | tee -a  $LOG_FILE

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installation of nodejs" | tee -a  $LOG_FILE
    
else
    echo -e "$Y The nodejs is already installed, nothing to do ... $N" | tee -a  $LOG_FILE
fi

#  making it idempotent with if condition
id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "The user expense is not yet created, $G we are creating now, please wait.. $N" | tee -a  $LOG_FILE
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Creating expense user" | tee -a  $LOG_FILE
else
    echo -e "The user expense is already exists. $G SKIPPING creating the user expense... $N"
fi

# idempotent
mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating /app foler" | tee -a  $LOG_FILE


curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code" | tee -a  $LOG_FILE

cd /app
rm -rf /app/* # we are removing existing code
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting backend application code" | tee -a  $LOG_FILE

# Installing nodejs dependencies
npm install &>>$LOG_FILE

# copying backend.service from expense-shell folder to /etc/systemd/system/ directory
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

# load the data before running backend, for this for install the mysql client
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installation of mysql client" | tee -a $LOG_FILE

# creating database and table structure in mysql server with the help of mysql client which we have installed in this backend, the script is there at /app/schema/backend.sql
# idempotent
mysql -h mysql.avk07.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema loading" | tee -a $LOG_FILE


systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon Reloading" | tee -a $LOG_FILE

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabling Backend" | tee -a $LOG_FILE

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarting the Backend" | tee -a $LOG_FILE

