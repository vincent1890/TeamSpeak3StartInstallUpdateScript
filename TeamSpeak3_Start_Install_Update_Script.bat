@ECHO off & SETlocal
::========================================================================
::
:: Tool Name : TeamSpeak3StartInstallUpdateScript
:: Author 	 : Vincent LAMY
:: Date 	 : 28/07/2020
:: Website	 : https://github.com/vincent1890/TeamSpeak3StartInstallUpdateScript/
::
::========================================================================

::--------------------------------------
:: Must be edited before use
::--------------------------------------
Rem Specify the address and port of your teamspeak3 api server
SET "URL=http://127.0.0.1:10080"
Rem Specify your KEY api server teamspeak3 (apikeyadd) HELP Here https://community.teamspeak.com/t/teamspeak-server-3-12-x/3916
SET "ApiKey=BABsnTr8Bu83fw05K9RTwQDqPliYAwYl8MnEmCC"
REM Change ByPassCheckIniFile to 1 for bypass verif if file ts3server.ini exist
SET "ByPassCheckIniFile=0"
REM Change ByPassUpdates to 1 for bypass updates server
SET "ByPassUpdates=0"
REM Change if your use SQLite or MySQL for DataBase server (By default SQLite is use)
SET "DbSQLiteMySQL=SQLite"



::--------------------------------------
:: Should not be edited except by expert
::--------------------------------------
SET "jsonfileTeamSpeakLocalVersion=LocalVersion.json"
SET "jsonfileTeamSpeakLastestVersion=LastestVersion.json"
SET "Commande_ProcessStop=/serverprocessstop"
SET "Commande_Version=/version"
SET "UrlJsonTeamSpeakLastestVersion=https://www.teamspeak.com/versions/server.json"
REM The TeamSpeakLocalVersion variable is initially created to avoid errors when installing from zero or if query_protocols has not been defined and the http api is not accessible.
SET "TeamSpeakLocalVersion=3.12.0"
SET "IsByPassUpdatesEnable=1"
SET "IsDbMySQL=MySQL"
IF %ByPassUpdates% equ %IsByPassUpdatesEnable% ( SET TeamSpeakLocalVersion=99.99.99 )


:DOWNLOAD-JSON-FILE
ECHO Download last version server teamspeak and local version for comparating ...
ECHO Please wait ...
ECHO.
curl -o %jsonfileTeamSpeakLastestVersion% -k -s %UrlJsonTeamSpeakLastestVersion%
curl -o %jsonfileTeamSpeakLocalVersion% -k -s -H "x-api-key: %ApiKey%" %URL%%Commande_Version%

TIMEOUT 2 /nobreak >nul

:PARSING-JSON-FILE
::--------------------------------------------
::Parsing Json TeamSpeak Lastest Version
set "psCmd2="add-type -As System.Web.Extensions;^
$JSON = new-object Web.Script.Serialization.JavaScriptSerializer;^
$JSON.DeserializeObject($input).windows.x86.version""

for /f %%I in ('^<"%jsonfileTeamSpeakLastestVersion%" powershell -noprofile %psCmd2%') do set "TeamSpeakLastestVersion=%%I"
::ECHO TeamSpeakLastestVersion: %TeamSpeakLastestVersion%
::--------------------------------------------
::Parsing Json TeamSpeak Local Version
set "psCmd1="add-type -As System.Web.Extensions;^
$JSON = new-object Web.Script.Serialization.JavaScriptSerializer;^
$JSON.DeserializeObject($input).body.version""

for /f %%I in ('^<"%jsonfileTeamSpeakLocalVersion%" powershell -noprofile %psCmd1%') do set "TeamSpeakLocalVersion=%%I"
::ECHO TeamSpeakLocalVersion: %TeamSpeakLocalVersion%
::--------------------------------------------

:CONVERT-VERSION-TO-NUMBER-AND-COMPARE
SET IntergerTeamSpeakLocalVersion=%TeamSpeakLocalVersion%
SET IntergerTeamSpeakLastestVersion=%TeamSpeakLastestVersion%
SET IntergerTeamSpeakLocalVersion=%IntergerTeamSpeakLocalVersion:.=%
SET IntergerTeamSpeakLastestVersion=%IntergerTeamSpeakLastestVersion:.=%
IF %IntergerTeamSpeakLastestVersion% equ %IntergerTeamSpeakLocalVersion% Goto :PASSED
IF %IntergerTeamSpeakLastestVersion% gtr %IntergerTeamSpeakLocalVersion% Goto :STOP-SERVER

:PASSED
ECHO PASSED
ECHO Update not required
ECHO.
TIMEOUT 5 /nobreak >nul
Goto :CHECK-INI-FILE

:STOP-SERVER
ECHO Stopping Serveur Teamspeak by API ...
ECHO Please wait ...
curl -o %jsonfileTeamSpeakLocalVersion% -k -s -H "x-api-key: %ApiKey%" %URL%%Commande_ProcessStop%
TIMEOUT 10 /nobreak >nul
ECHO Serveur Teamspeak STOPPING
ECHO.
Goto :BACKUP

:BACKUP
ECHO Backup Serveur Teamspeak ...
ECHO.
Goto :DOWNLOAD-INSTALL-UPDATES

:DOWNLOAD-INSTALL-UPDATES
ECHO Downloading last version ...
ECHO Please wait ...
ECHO.
SET "DownloadUrlTeamSpeakLastestVersion=https://files.teamspeak-services.com/releases/server/%TeamSpeakLastestVersion%/teamspeak3-server_win64-%TeamSpeakLastestVersion%.zip"
SET DownloadPath=%~dp0teamspeak3-server_win64-%TeamSpeakLastestVersion%.zip
SET Directory=%~dp0
%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe -Command "& {Import-Module BitsTransfer;Start-BitsTransfer '%DownloadUrlTeamSpeakLastestVersion%' '%DownloadPath%';$shell = new-object -com shell.application;$zip = $shell.NameSpace('%DownloadPath%');foreach($item in $zip.items()){$shell.Namespace('%Directory%').copyhere($item, 0x14)};remove-item '%DownloadPath%';}"
ECHO Download complete and extracted to the directory.
IF %DbSQLiteMySQL% == %IsDbMySQL% ( ECHO F|xcopy /y "%~dp0teamspeak3-server_win64\redist\libmariadb.dll" "%~dp0teamspeak3-server_win64\libmariadb.dll" /K /D )
Goto :CHECK-INI-FILE

:CHECK-INI-FILE
IF %ByPassCheckIniFile% == "1" ( Goto :LAUNCH )
IF Exist "%~dp0teamspeak3-server_win64\ts3server.ini" ( Goto :LAUNCH )
cls 
color DE
TIMEOUT 1 >nul 
color ED
TIMEOUT 1 >nul 
color DE
TIMEOUT 1 >nul 
color ED
TIMEOUT 1 >nul
ECHO.
ECHO Would you like to create the ts3serveur.ini file in the TeamSpeak3 server ?
ECHO.
ECHO  Tape Y for Yes
ECHO  Tape N for No
ECHO  Taper exit for QUIT
ECHO.
SET choix=ppppp 
:: SET choix=ppppp permet apr่s le IF %choix% EQU ppppp ce qui fait que m๊me si on entre rien et bien il remet au d้but
SET /p choix=Would you like to create the ts3serveur.ini file in the TeamSpeak3 server ?
IF /I %choix% EQU ppppp ECHO /!\Choix Invalide ! &pause &goto :CHECK-INI-FILE
IF /I %choix% EQU Y ECHO Vous avez entre Yes ! &goto :CREATE-INI-FILE
IF /I %choix% EQU N ECHO Vous avez entre No ! &goto :LAUNCH
IF /I %choix% EQU exit ECHO Vous avez entre Exit ! &goto :Exit
ECHO /!\Choix Invalide !
Pause
GOTO :CHECK-INI-FILEt

:CREATE-INI-FILE
cls 
color 4E
TIMEOUT 1 >nul 
color E4
TIMEOUT 1 >nul 
color 4E
TIMEOUT 1 >nul 
color E4
TIMEOUT 1 >nul 
start "TS3serveur" /D "%~dp0teamspeak3-server_win64\" ts3server.exe createinifile=1
ECHO Starting Server TEAMSPEAK3 ...
ECHO Please wait ...
ECHO.
IF NOT Exist "%~dp0teamspeak3-server_win64\.ts3server_license_accepted" ( TIMEOUT 10 /nobreak >nul )
ECHO.
ECHO Opening %~dp0teamspeak3-server_win64\ts3server.ini in notepad ...
ECHO.
ECHO Edit file ts3server.ini (add http to "query_protocols") and other if necessary.
start notepad %~dp0teamspeak3-server_win64\ts3server.ini
ECHO.
ECHO.
ECHO WAIT editing file ...
ECHO.
TIMEOUT 10 /nobreak >nul
ECHO Stop your server TEAMSPEAK3 manually
ECHO AND
ECHO Press key for restart server after edit file.
ECHO.
Pause

:LAUNCH
Rem Add Check no process ts3server open
ECHO Starting Server TEAMSPEAK3 ...
ECHO Please wait ...
ECHO.
start "TS3serveur" /D "%~dp0teamspeak3-server_win64\" ts3server.exe inifile=ts3server.ini
Goto :EXIT

:Exit
Goto :EOF
