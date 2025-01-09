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
N="\e[0m" # no color


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

dnf list installed nodejs &>> $LOG_FILE
if [ $? -ne 0 ]
then 
    echo "The nodejs is not installed, we are going to install it.." | tee -a  $LOG_FILE
    dnf module disable nodejs -y &>> $LOG_FILE
    VALIDATE $? "Disabling nodejs current version" | tee -a  $LOG_FILE

    dnf module enable nodejs:20 -y &>> $LOG_FILE
    VALIDATE $? "Enabling nodejs:20 version" | tee -a  $LOG_FILE

    dnf install nodejs -y &>> $LOG_FILE
    VALIDATE $? "Installation of nodejs" | tee -a  $LOG_FILE
    
else
    echo -e "$Y The nodejs is already installed, nothing to do ... $N" | tee -a  $LOG_FILE
fi

id expense &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "The user expense is not yet created, $G so creating now.. $N" | tee -a  $LOG_FILE
    useradd expense &>> $LOG_FILE
    VALIDATE $? "Creating expense user" | tee -a  $LOG_FILE
else
    echo -e "The user expense is already exists. $G SKIPPING creating the user expense... $N"
fi

