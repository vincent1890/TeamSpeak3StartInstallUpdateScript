# TeamSpeak3 Start-Install-Update Script-Windows
**Auto Install and Update if necessary the Windows TeamSpeak 3 Server on Windows 10 / server 2008 R2 / server 2016 / server 2019**

## Table of content

- [Developers](#developers)
- [Contributors](#contributors)
- [Donations](#donations)
- [Main Features](#main-features)
- [Stay tuned!](#stay-tuned)
- [Requirements](#requirements)
- [Supports](#supports)
- [How install script](#How install script)
- [Work flow of the script](#work-flow-of-the-script)
- [Used Resources by the script](#used-resources-by-the-script)
- [Directory Structure - Where can I find which file?](#directory-structure---where-can-i-find-which-file)
- [Why does this have a high version number?](#why-does-this-have-a-high-version-number)

## Developers

  * Vincent LAMY [contact@srvserveur.com]

## Contributors

[Open list of contributors](graphs/contributors)

## Donations

**TeamSpeak3StartInstallUpdateScript** is free software and is made available free of charge. Your donation, which is purely optional, supports me at improving the software as well as reducing my costs of this project. If you like the software, please consider a donation. Thank you very much!

[Donate with PayPal](https://www.paypal.me/SRVServeur)

## Main features

- Auto detection

## Requirements

- Windows (should work on the most distributions; below a list of explicit tested distributions)
  - server 2008 R2
  - server 2016
  - Server 2019
- NOT TeamSpeak 3 server instances start on server/VPS/virtual machine
- Software packages
  - Required
    - curl (If use windows server 2008 R2)
- Optional
    - telnet (The telnet client) (if you want add/create key api for shutdown serveur and update)

## Supports

- Windows 10 / server 2008/2016/2019


## Stay tuned!

- [GitHub](/)

## How install script

- Only follow up if a teamspeak server not already exists
1. Create directory (On "c:\" or other) to deposit the scripts
2. Download latest TeamSpeak3StartInstallUpdateScript and deposit the scripts
3. Start latest TeamSpeak3StartInstallUpdateScript.bat
4. Follow the instructions given in the console
5. Connectez vous avec telnet pour créer un clé API manager
6. Edit the script and specify the API key so that the script can perform all the Update operations alone the next time 
7. Good job your teamspeak server is now starting and completely up to date
8. The next time the script runs it will check if an update exists and if it does, it will turn it off, save, update the server and restart it on its own.


- Only follow up if a teamspeak server already exists
1. Create directory (On "c:\" or other) to deposit the scripts
2. Download latest TeamSpeak3StartInstallUpdateScript and deposit the scripts
3. Stop running TSDNS (if used)
4. Stop running server instance gracefully
5. Backup server (if any is available)
6. Start latest TeamSpeak3StartInstallUpdateScript.bat
7. Follow the instructions given in the console
8. At the END stop running the server instance gracefully
9. Import licensekey (if available), database, Query IP Black - Whitelist, files and logs from backup
10. Import TSDNS settings file (if used)
11. Restart TeamSpeak3StartInstallUpdateScript.bat
12. Connectez vous avec telnet pour créer un clé API manager
13. Edit the script and specify the API key so that the script can perform all the Update operations alone the next time 
14. Good job your teamspeak server is now starting and completely up to date
15. The next time the script runs it will check if an update exists and if it does, it will turn it off, save, update the server and restart it on its own.

The files/directories will not be touched by the script - also not backuped!


## Work flow of the script

First it will check if a newer version of the script is available; afterwards it will check your installed version of each instance against the latest available version from teamspeak.com. If a newer version is available, the script will do following steps:

1. check if an update exists and if it does
2. turn it off
3. save
4. update the serve
5. restart the serve

## Used Resources by the script

Protocol | Host/IP  | Used for | How often?
:------------- | :------------- | :------------- | :-------------
https | www.teamspeak.com | For detection of latest stable server release version | Each execution of the TeamSpeak3StartInstallUpdateScript
https | files.teamspeak-services.com | Download server for TeamSpeak 3 server files | Each execution of the TeamSpeak3StartInstallUpdateScript
https | raw.githubusercontent.com | Server for checking latest TeamSpeak3StartInstallUpdateScript version | Each execution of the TeamSpeak3StartInstallUpdateScript
https | github.com | Download server for TeamSpeak3StartInstallUpdateScript files | Only if you update the TeamSpeak3StartInstallUpdateScript
