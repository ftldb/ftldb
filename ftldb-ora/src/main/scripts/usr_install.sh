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

if [ $# -lt 3 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]
then
  echo Wrong parameters!
  echo Proper usage: $0 \<tns_name\> \<ftldb_schema\> \<ftldb_pswd\>
  echo Example: $0 orcl ftldb ftldb
  exit 1
fi

tns_name=$1
ftldb_schema=$2
ftldb_pswd=$3
logfile="!$(basename $0 .sh)_${1}_${2}.log"
jarfile="!missing_${1}_${2}.jar"

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
sqlplus -L $ftldb_schema/$ftldb_pswd@$tns_name \
  @setup/usr_install setup/$logfile

exit_if_failed $?

# Determine Oracle version.
ora_release="$(sqlplus -S -L $ftldb_schema/$ftldb_pswd@$tns_name @setup/get_oracle_release)"

if [ "${ora_release:0:1}" = "1" ]; then
  if [ "${ora_release:0:2}" = "10" ]; then
    ora_11_or_higher="false"
  else
    ora_11_or_higher="true"
  fi
else
  echo [WARNING] Unknown or unsupported Oracle version: $ora_release.
  ora_11_or_higher="false"
fi

if [ "$ora_11_or_higher" = "true" ]; then

  echo
  echo Load and resolve freemarker.jar classes into database, generate missing classes \(setup/$jarfile\).
  loadjava -user $ftldb_schema/$ftldb_pswd@$tns_name \
    -resolve -genmissingjar setup/$jarfile \
    -verbose -stdout \
    java/freemarker.jar \
    1>> setup/$logfile

  exit_if_failed $?

else

  echo
  echo Load and resolve freemarker.jar classes into database, ignore missing classes.
  loadjava -user $ftldb_schema/$ftldb_pswd@$tns_name \
    -resolve -unresolvedok \
    -verbose -stdout \
    java/freemarker.jar \
    1>> setup/$logfile

  exit_if_failed $?

fi

echo
echo Load and resolve ftldb.jar classes into database.
loadjava -user $ftldb_schema/$ftldb_pswd@$tns_name \
  -resolve \
  -verbose -stdout \
  java/ftldb.jar \
  1>> setup/$logfile

exit_if_failed $?

echo
echo -------------------------------------------
echo --- INSTALLATION COMPLETED SUCCESSFULLY ---
echo -------------------------------------------
exit 0
