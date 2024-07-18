#!/bin/bash
DB_HOSTNAME=$(cat /conjur/secrets/secrets.json | jq -r .\"DB_HOSTNAME\")
DB_NAME=$(cat /conjur/secrets/secrets.json | jq -r .\"DB_NAME\")
DB_UNAME=$(cat /conjur/secrets/secrets.json | jq -r .\"DB_UNAME\")
DB_PWD=$(cat /conjur/secrets/secrets.json | jq -r .\"DB_PWD\")

echo
echo "DB hostname is: $DB_HOSTNAME"
echo "DB name is: $DB_NAME"
echo "DB username is: $DB_UNAME"
echo "DB password is: $DB_PWD"
echo

set -x
mysql -A -h $DB_HOSTNAME -u $DB_UNAME --password=$DB_PWD $DB_NAME
