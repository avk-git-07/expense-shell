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

echo "Script started executing at : $TIMESTAMP" | tee -a  $LOG_FILE

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

dnf install mysql-server -y
VALIDATE $? "Installing mysql server"

systemctl enable mysqld
VALIDATE $? "Enabling mysql server"

systemctl start mysqld
VALIDATE $? "Starting mysql server"

mysql_secure_installation --set-root-pass ExpenseApp@1
VALIDATE $? "Setting up root password"
