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
if "%~4" == "" goto :usage
if /i not "%~5" == "grant" if /i not "%~4" == "revoke" goto :usage
if "%~6" == "" goto :usage

set tns_name=%1
set super_user=%2
set super_user_pswd=%3
set ftldb_schema=%4
set action=%5
set "logfile=^!%~n0_%1.log"
set "sqlfile=^!%~n0_%1.sql"

if /i "%super_user%" == "sys" set "sys_option=as sysdba"

echo -------------------------------------------
echo ------- SWITCHING PL/SQL PRIVILEGES -------
echo -------------------------------------------
echo.
echo Log file: setup\%logfile%

echo.
echo Build SQL*Plus script.
type nul 1> setup\%sqlfile%
setlocal enabledelayedexpansion
set i=0
for %%v in (%*) do (
  set /a i+=1
  if !i! geq 6 echo @@switch_plsql_privileges %ftldb_schema% %action% %%v 1>> "setup\%sqlfile%"
)
endlocal

echo.
echo Run SQL*Plus script.
sqlplus -L %super_user%/%super_user_pswd%@%tns_name% %sys_option% ^
  @setup/run_script @%sqlfile% setup/%logfile%

if errorlevel 1 goto :failure

echo.
echo -------------------------------------------
echo ------ SCRIPT COMPLETED SUCCESSFULLY ------
echo -------------------------------------------
exit /B 0

:failure
echo.
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo !!!!!!!!!!!!!! SCRIPT FAILED !!!!!!!!!!!!!!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
exit /B 1

:usage
echo Wrong parameters!
echo Proper usage: %~nx0 ^<tns_name^> ^<super_user^> ^<super_user_pswd^> ^<ftldb_schema^> grant^|revoke ^<grantee1^> [^<grantee2^> [^<grantee3^> ...]]
echo Example: %~nx0 orcl sys manager ftldb grant hr oe pm sh
exit /B 1
