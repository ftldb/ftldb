@REM
@REM Copyright 2014-2016 Victor Osolovskiy, Sergey Navrotskiy
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
if "%~4" == "" goto :usage
if "%~5" == "" goto :usage
if "%~6" == "" goto :usage

set tns_name=%1
set super_user=%2
set super_user_pswd=%3
set ftldb_schema=%4
set demo_schema=%5
set demo_pswd=%6
set "logfile=^!%~n0_%1_%5.log"
set "sqlfile=^!%~n0_%1_%5.sql"

echo -------------------------------------------
echo ---------- INSTALLING FTLDB DEMO ----------
echo -------------------------------------------
echo.
echo Log file: setup\%logfile%

echo.
echo Build SQL*Plus installation script.
java -cp .;java/* ftldb.CommandLine @setup/install.ftl ^
  %tns_name% %super_user% %ftldb_schema% %demo_schema% ^
  1> setup\%sqlfile% 2> setup\%logfile%

if errorlevel 1 goto :failure

echo.
echo SQL file: setup\%sqlfile%

echo.
echo Run SQL*Plus installation script.
sqlplus /nolog @setup/%sqlfile% %super_user_pswd% %demo_pswd% setup/%logfile%

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
echo Proper usage: %~nx0 ^<tns_name^> ^<super_user^> ^<super_user_pswd^> ^<ftldb_schema^> ^<demo_schema^> ^<demo_pswd^>
echo Example: %~nx0 orcl sys manager ftldb ftldemo ftldemo
exit /B 1
