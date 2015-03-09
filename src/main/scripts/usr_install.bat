@REM
@REM Copyright 2014-2015 Victor Osolovskiy, Sergey Navrotskiy
@REM
@REM Licensed under the Apache License, Version 2.0 (the "License");
@REM you may not use this file except in compliance with the License.
@REM You may obtain a copy of the License at
@REM
@REM     http://www.apache.org/licenses/LICENSE-2.0
@REM
@REM Unless required by applicable law or agreed to in writing, software
@REM distributed under the License is distributed on an "AS IS" BASIS,
@REM WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@REM See the License for the specific language governing permissions and
@REM limitations under the License.
@REM

@echo off
if "%~1" == "" goto :usage
if "%~2" == "" goto :usage
if "%~3" == "" goto :usage

set instance_tns_name=%1
set ftldb_schema=%2
set ftldb_pswd=%3
set "logfile=^!%~n0_%1_%2.log"

echo -------------------------------------------
echo ------------ INSTALLING FTLDB -------------
echo -------------------------------------------
echo.
echo Log file: setup\%logfile%

echo.
echo Run SQL*Plus installation script.
sqlplus -L %ftldb_schema%/%ftldb_pswd%@%instance_tns_name% ^
  @setup/usr_install setup/%logfile%

if errorlevel 1 goto :failure

echo.
echo Load freemarker.jar classes into database.
call loadjava -user %ftldb_schema%/%ftldb_pswd%@%instance_tns_name% ^
  -grant public ^
  -resolve -unresolvedok ^
  -verbose -stdout ^
  java/freemarker.jar ^
  1>> setup\%logfile%

if errorlevel 1 goto :failure

echo.
echo Load ftldb.jar classes into database.
call loadjava -user %ftldb_schema%/%ftldb_pswd%@%instance_tns_name% ^
  -grant public ^
  -resolve ^
  -verbose -stdout ^
  java/ftldb.jar ^
  1>> setup\%logfile%

if errorlevel 1 goto :failure

echo.
echo -------------------------------------------
echo --- INSTALLATION COMPLETED SUCCESSFULLY ---
echo -------------------------------------------
exit /B 0

:failure
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo !!!!!!!!!! INSTALLATION FAILED !!!!!!!!!!!!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
exit /B 1

:usage
echo Wrong parameters!
echo Proper usage: %~nx0 instance_tns_name ftldb_schema ftldb_pswd
echo Example: %~nx0 orcl ftldb ftldb
exit /B 1
