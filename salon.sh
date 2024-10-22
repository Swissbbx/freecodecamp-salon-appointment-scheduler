#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~"

echo -e "\nWelcome to My Salon, how can I help you?\n"


MAIN_MENU() {

  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  SERVICES=$($PSQL "SELECT * FROM services")
  echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  read SERVICE_ID_SELECTED

  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    CREATE_APPOINTMENT $SERVICE_ID_SELECTED
  fi

}

CREATE_APPOINTMENT() {
  SERVICE_ID_SELECTED=$($PSQL "SELECT service_id FROM services WHERE service_id = $1")
  
  if [[ -z $SERVICE_ID_SELECTED ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE

    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    if [[ -z $CUSTOMER_ID ]]
    then
      echo -e "\nI don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME
      CUSTOMER_ID=$( echo $($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME') RETURNING customer_id") | sed -E 's/INSERT 0 1$//')
    fi

    CUSTOMER_NAME=$(echo $($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID") | sed 's/^ *| *$//g')
    SERVICE_NAME=$(echo $($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED") | sed 's/^ *| *$//g')

    echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
    read SERVICE_TIME

    APPOINTMENT_ID=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."

  fi
}

MAIN_MENU