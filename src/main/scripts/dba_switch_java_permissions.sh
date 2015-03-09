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

if [ $# -lt 5 ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] ||
  ([ "$(echo $4 | tr 'A-Z' 'a-z')" != "grant" ] && [ "$(echo $4 | tr 'A-Z' 'a-z')" != "revoke" ])
then
  echo Wrong parameters!
  echo Proper usage: $0 instance_tns_name super_user super_user_pswd grant\|revoke grantee1 [grantee2 [grantee3 ...]]
  echo Example: $0 orcl sys manager grant hr oe pm sh
  exit 1
fi

instance_tns_name=$1
super_user=$2
super_user_pswd=$3
switch=$4
logfile="!$(basename $0 .sh)_${1}.log"
sqlfile="!$(basename $0 .sh)_${1}.sql"

if [ "$(echo ${super_user} | tr 'A-Z' 'a-z')" = "sys" ]; then
  sys_option="as sysdba"
fi

exit_if_failed () {
  if [ "$1" -gt 0 ]; then
    echo
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo !!!!!!!!!!!!!! SCRIPT FAILED !!!!!!!!!!!!!!
    echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    exit 1
  fi
}

echo -------------------------------------------
echo ------- SWITCHING JAVA PERMISSIONS --------
echo -------------------------------------------
echo
echo Log file: setup/$logfile

echo
echo Build SQL*Plus script.
1> setup/$sqlfile
i=0
for v in "$@"; do
  i=`expr $i + 1`
  if [ $i -ge 5 ]; then
    echo @@switch_java_permissions $switch $v 1>> setup/$sqlfile
  fi
done

echo
echo Run SQL*Plus script.
sqlplus -L $super_user/$super_user_pswd@$instance_tns_name $sys_option \
  @setup/run_script @$sqlfile setup/$logfile

exit_if_failed $?

echo
echo -------------------------------------------
echo ------ SCRIPT COMPLETED SUCCESSFULLY ------
echo -------------------------------------------
exit 0
