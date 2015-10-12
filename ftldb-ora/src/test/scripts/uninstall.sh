#!/bin/sh
#
# Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ $# -lt 4 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]
then
  echo Wrong parameters!
  echo Proper usage: $0 instance_tns_name super_user super_user_pswd demo_schema
  echo Example: $0 orcl sys manager ftldemo
  exit 1
fi

instance_tns_name=$1
super_user=$2
super_user_pswd=$3
demo_schema=$4
logfile="!$(basename $0 .sh)_${1}_${4}.log"
sqlfile="!$(basename $0 .sh)_${1}_${4}.sql"

exit_if_failed () {
  if [ "$1" -gt 0 ]; then
    echo
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo !!!!!!!!! DEINSTALLATION FAILED !!!!!!!!!!!
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    exit 1
  fi
}

echo -------------------------------------------
echo --------- DEINSTALLING FTLDB DEMO ---------
echo -------------------------------------------
echo
echo Log file: setup/$logfile

echo
echo Build SQL*Plus deinstallation script.
java -cp .:java/ftldb.jar:java/freemarker.jar ftldb.CommandLine @setup/uninstall.ftl \
  $instance_tns_name $super_user $demo_schema \
  1> setup/$sqlfile 2> setup/$logfile

exit_if_failed $?

echo
echo SQL file: setup/$sqlfile

echo
echo Run SQL*Plus deinstallation script.
sqlplus /nolog @setup/$sqlfile $super_user_pswd setup/$logfile

exit_if_failed $?

echo
echo -------------------------------------------
echo -- DEINSTALLATION COMPLETED SUCCESSFULLY --
echo -------------------------------------------
exit 0
