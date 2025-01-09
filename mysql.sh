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

dnf list installed mysql-server &>> $LOG_FILE
if [ $? -ne 0 ]
then 
    echo "The MySQL Server is not installed, we are are install now, please wait.." | tee -a  $LOG_FILE
    dnf install mysql-server -y &>> $LOG_FILE
    VALIDATE $? "Installation of MySQL Server" | tee -a  $LOG_FILE
    
    systemctl enable mysqld &>> $LOG_FILE
    VALIDATE $? "Enabling mysql server" | tee -a  $LOG_FILE

    systemctl start mysqld &>> $LOG_FILE
    VALIDATE $? "Starting mysql server" | tee -a  $LOG_FILE

else
    echo -e "$Y The MySQL Server is already installed, nothing to do ... $N" | tee -a  $LOG_FILE
fi

mysql -h mysql.avk07.online -u root -pExpenseApp@1 -e 'show databases;' &>> $LOG_FILE
if [ $? -ne 0 ]
then 
    echo "MySQL root password is not setup, setting now" | tee -a  $LOG_FILE
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>> $LOG_FILE
    VALIDATE $? "Setting up root password" | tee -a  $LOG_FILE
else 
    echo -e "$G MySQL root password setup already done,.. $Y Skipping.. $N" | tee -a  $LOG_FILE
fi


