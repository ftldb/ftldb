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

set tns_name=%1
set ftldb_schema=%2
set ftldb_pswd=%3
set "logfile=^!%~n0_%1_%2.log"
set "jarfile=^!missing_%1_%2.jar"

echo -------------------------------------------
echo ------------ INSTALLING FTLDB -------------
echo -------------------------------------------
echo.
echo Log file: setup\%logfile%

echo.
echo Run SQL*Plus installation script.
sqlplus -L %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
  @setup/usr_install setup/%logfile%

if errorlevel 1 goto :failure

rem Determine Oracle version.
set "ora_release_cmd=sqlplus -S -L %ftldb_schema%/%ftldb_pswd%@%tns_name% @setup/get_oracle_release"
for /f %%i in ('%ora_release_cmd%') do set "ora_release=%%i"

if "%ora_release:~0,1%" == "1" (
  if "%ora_release:~0,2%" == "10" (
    set ora_11_or_higher=false
  ) else (
    set ora_11_or_higher=true
  )
) else (
  echo [WARNING] Unknown or unsupported Oracle version: %ora_release%.
  set ora_11_or_higher=false
)

if "%ora_11_or_higher%" == "true" (

  echo.
  echo Load and resolve freemarker.jar classes into database, generate missing classes ^(setup\%jarfile%^).
  call loadjava -user %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
    -resolve -genmissingjar setup/%jarfile% ^
    -verbose -stdout ^
    java/freemarker.jar ^
    1>> setup\%logfile%

  if errorlevel 1 goto :failure

) else (

  echo.
  echo Load and resolve freemarker.jar classes into database, ignore missing classes.
  call loadjava -user %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
    -resolve -unresolvedok ^
    -verbose -stdout ^
    java/freemarker.jar ^
    1>> setup\%logfile%

  if errorlevel 1 goto :failure

)

echo.
echo Load and resolve ftldb.jar classes into database.
call loadjava -user %ftldb_schema%/%ftldb_pswd%@%tns_name% ^
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
echo Proper usage: %~nx0 ^<tns_name^> ^<ftldb_schema^> ^<ftldb_pswd^>
echo Example: %~nx0 orcl ftldb ftldb
exit /B 1
