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

if [ $# -lt 5 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]
then
  echo Wrong parameters!
  echo Proper usage: $0 instance_tns_name super_user super_user_pswd ftldb_schema ftldb_pswd
  echo Example: $0 orcl sys manager ftldb ftldb
  exit 1
fi

instance_tns_name=$1
super_user=$2
super_user_pswd=$3
ftldb_schema=$4
ftldb_pswd=$5
logfile="!$(basename $0 .sh)_${1}_${4}.log"
jarfile="!missing_${1}_${4}.jar"

if [ "$(echo ${super_user} | tr 'A-Z' 'a-z')" = "sys" ]; then
  sys_option="as sysdba"
fi

exit_if_failed () {
  if [ "$1" -gt 0 ]; then
    echo
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo !!!!!!!!!! INSTALLATION FAILED !!!!!!!!!!!!
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    exit 1
  fi
}

echo -------------------------------------------
echo ------------ INSTALLING FTLDB -------------
echo -------------------------------------------
echo
echo Log file: setup/$logfile

echo
echo Run SQL*Plus installation script.
sqlplus -L $super_user/$super_user_pswd@$instance_tns_name $sys_option \
  @setup/dba_install $ftldb_schema $ftldb_pswd setup/$logfile

exit_if_failed $?

# Determine Oracle version.
ora_release="$(sqlplus -S -L $ftldb_schema/$ftldb_pswd@$instance_tns_name @setup/get_oracle_release)"

if [ "${ora_release:0:1}" = "1" ]; then
  if [ "${ora_release:0:2}" = "10" ]; then
    ora_11_or_higher="false"
  else
    ora_11_or_higher="true"
  fi
else
  echo Warning! Unknown or unsupported Oracle version: $ora_release.
  ora_11_or_higher="false"
fi

if [ "$ora_11_or_higher" = "true" ]; then

  echo
  echo Load freemarker.jar classes into database, generate missing classes \(setup/$jarfile\).
  loadjava -user $ftldb_schema/$ftldb_pswd@$instance_tns_name \
    -genmissingjar setup/$jarfile \
    -verbose -stdout \
    java/freemarker.jar \
    1>> setup/$logfile

  exit_if_failed $?

  echo
  echo Resolve freemarker.jar classes, grant execute privilege to PUBLIC.
  loadjava -user $ftldb_schema/$ftldb_pswd@$instance_tns_name \
    -resolveonly -grant public \
    -verbose -stdout \
    java/freemarker.jar \
    1>> setup/$logfile

  exit_if_failed $?

else

  echo
  echo Load and resolve freemarker.jar classes into database, ignore missing classes, grant execute privilege to PUBLIC.
  loadjava -user $ftldb_schema/$ftldb_pswd@$instance_tns_name \
    -resolve -unresolvedok -grant public \
    -verbose -stdout \
    java/freemarker.jar \
    1>> setup/$logfile

  exit_if_failed $?

fi

echo
echo Load and resolve ftldb.jar classes into database, grant execute privilege to PUBLIC.
loadjava -user $ftldb_schema/$ftldb_pswd@$instance_tns_name \
  -resolve -grant public \
  -verbose -stdout \
  java/ftldb.jar \
  1>> setup/$logfile

exit_if_failed $?

echo
echo -------------------------------------------
echo --- INSTALLATION COMPLETED SUCCESSFULLY ---
echo -------------------------------------------
exit 0
