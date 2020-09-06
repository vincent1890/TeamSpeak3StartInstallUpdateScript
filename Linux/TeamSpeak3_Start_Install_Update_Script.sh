#!/bin/bash
#
# TeamSpeak3_Start_Install_Update_Script
#
# Open Ports for server
# https://support.teamspeak.com/hc/en-us/articles/360002712257-Which-ports-does-the-TeamSpeak-3-server-use-
#

## ------------------- ##
## VARIABLES CAN EDIT  ##
## ------------------- ##
# Change ByPassCheckIniFile to 1 for bypass verif if file ts3server.ini exist
ByPassCheckIniFile=0
# Change ByPassUpdates to 1 for bypass updates server
ByPassUpdates=0
# Change if your use SQLite or MariaDB for DataBase server (By default SQLite is use)
Db_Type=SQLite
# For active debug change (0=disable) and (1=active)
Debug=0
# SSH PORTS session (By defaut 22)
PortSessionSSH=22
# Query protocols API (0=disable) and (1=active)
UseQueryHTTP=1
UseQueryHTTPS=1
# TeamSpeak PORTS
PortVoice=9987
PortFileTransfer=30033
# Query PORTS
PortQuerySSH=10022
PortQueryHTTP=10080
PortQueryHTTPS=10443

## ---------------------------------------------------------------  ##
## _________________________ONLY EXPERT___________________________  ##
## ____________________________AFTER______________________________  ##
## ---------------------------------------------------------------  ##
## ------------------- ##
## VARIABLES NOT EDIT  ##
## ------------------- ##
# User use for start server
TS3_USER="teamspeak3"
# Directory stock download
#TMP_DIR_DOWNLOAD="/tmp/DownloadTS3"
TMP_DIR_DOWNLOAD="/home/teamspeak3"
# Query protocols API active by defaut
UseQuerySSH=1
# Host LOCALHOST
REMOTEHOST=127.0.0.1
# Timeout test telnet
TIMEOUT=5
# Query port by defaut
ServerQuery=10011
Query_protocols=raw
# URL file teamspeak server 
URLBASE_TS3SERVER_FILE="https://files.teamspeak-services.com/releases/server/"

## ------------------- ##
##  VARIABLES NOT USE  ##
## ------------------- ##
# Adresse server TS3server
URL=http://127.0.0.1:10080
# Specify your KEY api server teamspeak3 (apikeyadd) HELP Here https://community.teamspeak.com/t/teamspeak-server-3-12-x/3916
ApiKey="BABsnTr8B785kjgh99RTwQDqPliYAwYl8MnEmC"
# URL json last version server
UrlJsonTeamSpeakLastestVersion="https://www.teamspeak.com/versions/server.json"
# API command
jsonfileTeamSpeakLocalVersion="LocalVersion.json"
jsonfileTeamSpeakLastestVersion="LastestVersion.json"
Command_ProcessStop="serverprocessstop"
Command_Version="version"
# Modify variable DirBackup for indique directory backup Teamspeak-Server by default directory .\Backup ("DirBackup=%~dp0Backup")
#DirBackup=Backup
# Modify variable DirZipBackup for indique directory where Backup file zip by default directory .\Archives ("DirBackup=%~dp0Backup")
#DirZipBackup=Backup
#SourceZipDirectory=$DirBackup/teamspeak3-server_win64/
#DestZipFile=$DirZipBackup/NameBackup.zip
#NameBackup=Backup_TS3server_DateHeure
# ---------------------------------------------------------------------

## exit with a non-zero status when there is an uncaught error
set -e

## are we root?
if  [ "$EUID" -ne 0 ]; then
  echo -e "\nERROR!!! SCRIPT MUST RUN WITH ROOT PRIVILAGES\n"
  exit 1
fi

## Fonction PAUSE how use : pause 'Edit file ts3server.ini if necessary and Press [Enter] key to continue...'
function pause(){
   read -p "$*"
}

## Function test app installed
exists()
{
  command -v "$1" >/dev/null 2>&1
}

## Get Public IP
PUBLIC_IP=$(curl -s ifconfig.co)
EXTERNAL_IP=$(wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<Ip>\(.*\)<\/Ip>.*/\1/p')
PUBLIC_IP_OPENDNS=$(dig +short myip.opendns.com @resolver1.opendns.com)

## Function install
function apt_install() {
	sudo apt-get install -y $1 > /dev/null
}

## Install curl if no exist
if exists curl; then
	if [[ $Debug == "1" ]]; then
		echo ""
		echo "Curl exists!"
		echo ""
	fi
else
	apt_install curl
fi


## Check want Query_protocols by user
if [[ $UseQuerySSH == "1" ]]; then
	Query_protocols="$Query_protocols,ssh"
fi
if [[ $UseApiHTTP == "1" ]]; then
	Query_protocols="$Query_protocols,http"
fi
if [[ $UseApiHTTPS == "1" ]]; then
	Query_protocols="$Query_protocols,https"
fi

## Add Rules firewall
FirewallRules() {
echo ""
echo "OUT - Accounting TeamSpeak3"
sudo ufw allow out 443/tcp # Accounting TeamSpeak3
echo ""
echo "OUT - weblist TeamSpeak3"
sudo ufw allow out 2010/udp # weblist
echo ""
echo "IN - Voice TeamSpeak3"
sudo ufw allow $PortVoice/udp # Voice
echo ""
echo "IN - ServerQuery TeamSpeak3"
sudo ufw allow $ServerQuery/tcp # ServerQuery (raw - Telnet)
echo ""
echo "IN - File Transfer TeamSpeak3"
sudo ufw allow $PortFileTransfer/tcp # Filetransfer
echo ""
echo "IN - TSDNS TeamSpeak3"
sudo ufw allow 41144/tcp # TSDNS
if [[ $UseQuerySSH == "1" ]]; then
	echo ""
	echo "IN - Query SSH TeamSpeak3"
	sudo ufw allow $PortQuerySSH/tcp # ServerQuery (SSH)
fi
if [[ $UseApiHTTP == "1" ]]; then
	echo ""
	echo "IN - Api HTTP TeamSpeak3"
	sudo ufw allow $PortQueryHTTPS/tcp # Requete Web (https)
fi
if [[ $UseApiHTTPS == "1" ]]; then
	echo ""
	echo "IN - Api HTTPS TeamSpeak3"
	sudo ufw allow $PortQueryHTTPS/tcp # Requete Web (https)
fi
echo ""
sudo ufw allow $PortSessionSSH/tcp
echo ""
yes | sudo ufw enable
}

## Function create service on system for restart auto
CreateService() {
cat > /etc/systemd/system/teamspeak.service << EOF
[Unit]
Description=TeamSpeak3 Server
Wants=network-online.target
After=syslog.target network.target

[Service]
WorkingDirectory=$TS3_DIR
User=$TS3_USER
Type=forking
Restart=always
ExecStart=$TS3_DIR/ts3server_startscript.sh start inifile=$TS3_DIR/ts3server.ini
ExecStop=$TS3_DIR/ts3server_startscript.sh stop
ExecReload=$TS3_DIR/ts3server_startscript.sh reload
PIDFile=$TS3_DIR/ts3server.pid
RestartSec=15
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl --system daemon-reload
systemctl enable teamspeak.service
}

#function _apt_available() {
#    if [ `apt-cache search $1 | grep -o "$1" | uniq | wc -l` = "1" ]; then
#        echo "Package is available : $1"
#        PACKAGE_INSTALL="1"
#    else
#        echo "Package $1 is NOT available for install"
#        echo  "We can not continue without this package..."
#        echo  "Exitting now.."
#        exit 0
#    fi
#}

## Check if user exists
if getent passwd $TS3_USER > /dev/null 2>&1; then
    #echo "User alrealy exist"
	echo ""
else
    ## add the user to run ts3server
	echo "No, the user does not exist"
	# if adduser --system --group --disabled-login --disabled-password --no-create-home "$TS3_USER" >/dev/null 2>&1; then
	if adduser --system --shell /bin/bash --group --disabled-password --home /home/$TS3_USER $TS3_USER >/dev/null 2>&1; then
	  echo -e "\nAdded new user: '$TS3_USER'"
	else
	  echo -e "ERROR!!! Failed to add new user: '$TS3_USER'"
	  exit 1
	fi
fi

## Function get latest version
Check_LATEST_VER() {
TS3_LATEST_VER=`curl $URLBASE_TS3SERVER_FILE --silent | sed -e 's/<[^>]*.//g' | grep '^[0-9]' | sort -r -V | head -n 1`
TS3_LATEST_VER=${TS3_LATEST_VER//[^0-9.]/}
}

## check if we need 64bit or 32bit binaries
Arch=$(arch)
if [ "$Arch" = "x86_64" ]; then
	TS3_ARCH_FILE="amd64"
elif [ "$Arch" = "i386" ]; then
	TS3_ARCH_FILE="x86"
elif [ "$Arch" = "i686" ]; then
	TS3_ARCH_FILE="x86"
fi

TS3_DIR="/opt/teamspeak3-server_linux_$TS3_ARCH_FILE"

## Function get local version
Check_LOCAL_VER() {
	# determine installed version by parsing the most recent entry of the CHANGELOG file
	if [ -f $TS3_DIR/CHANGELOG ]; then
		TS3_LOCAL_VER=$(grep -Eom1 'Server Release \S*' "$TS3_DIR/CHANGELOG" | cut -b 16-)
	else
		TS3_LOCAL_VER='3.12.0'
	fi
}

Check_LATEST_VER
Check_LOCAL_VER
TS3_FILE_COMPRESSED="teamspeak3-server_linux_$TS3_ARCH_FILE-$TS3_LATEST_VER.tar.bz2"
URLCOMPLET_TS3SERVER_FILE="$URLBASE_TS3SERVER_FILE$TS3_LATEST_VER/$TS3_FILE_COMPRESSED"

Download() {
	if [[ $ByPassUpdates == "0" ]]; then
		## Compare version
		if [ "$TS3_LOCAL_VER" != "$TS3_LATEST_VER" ]; then
			echo "New version available: $TS3_LATEST_VER found, downloading..."
			TS3_NewVersion=1
			if [ -d $TMP_DIR_DOWNLOAD ]; then
				echo "Directory exists"
				#sudo chown "$TS3_USER":"$TS3_USER" $TS3_DIR -R
				#chmod 777 $TS3_DIR
			else
				mkdir $TMP_DIR_DOWNLOAD
				#sudo chown "$TS3_USER":"$TS3_USER" $TS3_DIR -R
				#chmod 777 $TS3_DIR
			fi
			## Download TeamSpeak3 server
			wget –q -A "tar.bz2" –O $TS3_FILE_COMPRESSED -P $TMP_DIR_DOWNLOAD $URLCOMPLET_TS3SERVER_FILE  | bash
		else
			TS3_NewVersion=0
			echo "" &&>> tsinstall.log
			echo "No new version" &&>> tsinstall.log
			echo "Local version : $TS3_LOCAL_VER" &&>> tsinstall.log
			echo "Last version : $TS3_LATEST_VER" &&>> tsinstall.log
			echo "Finish" &&>> tsinstall.log
			echo "" &&>> tsinstall.log
			echo ""
			echo -e "Your servers external IP Address is: $EXTERNAL_IP"
			echo ""
		fi
	fi
}

Update() {
	Download
	if [[ $TS3_NewVersion == "1" ]]; then
		## TeamSpeak 3 server alrealy exist
		su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh stop"
		if [ -d $TS3_DIR ]; then
			if [[ $Debug == "1" ]]; then
				echo ""
				echo "$TS3_DIR exist"
				echo ""
			fi
			## Test if download file compress exist
			if [ -f $TMP_DIR_DOWNLOAD/$TS3_FILE_COMPRESSED ]; then
				if [[ $Debug == "1" ]]; then
					echo ""
					echo "$TMP_DIR_DOWNLOAD/$TS3_FILE_COMPRESSED exist"
					echo ""
				fi
				## Extracting
				if [[ $Debug == "1" ]]; then
					echo ""
					echo "extracting..."
					echo ""
				fi
				su $TS3_USER -c "tar -C $TMP_DIR_DOWNLOAD -xjf $TMP_DIR_DOWNLOAD/$TS3_FILE_COMPRESSED"
				## Move new or update files in folder Teamspeak 3 server
				if [[ $Debug == "1" ]]; then
					echo ""
					echo "Move new or update files in folder Teamspeak 3 server..."
					echo ""
				fi
				#y | mv -f $TMP_DIR_DOWNLOAD/teamspeak3-server_linux_$TS3_ARCH_FILE/* $TS3_DIR
				rsync -a $TMP_DIR_DOWNLOAD/teamspeak3-server_linux_$TS3_ARCH_FILE/ $TS3_DIR/
				## Test if Type DataBase is MariaDB in option
				if [[ $Db_Type == "MariaDB" ]]; then
					su $TS3_USER -c "ln -s $TS3_DIR/redist/libmariadb.so.2 $TS3_DIR/libmariadb.so.2"
					su $TS3_USER -c "ldd $TS3_DIR/libts3db_mariadb.so"
				fi
				## Delete files compress
				if [[ $Debug == "1" ]]; then
					echo ""
					echo "Delete files compress and others ..."
					echo ""
				fi
				rm -rf $TMP_DIR_DOWNLOAD/$TS3_FILE_COMPRESSED
				## Make scripts executable
				sudo chmod a+x $TS3_DIR/ts3server_startscript.sh
				sudo chmod a+x $TS3_DIR/ts3server_minimal_runscript.sh
				## Check if ini file must be created
				if [[ $ByPassCheckIniFile == "0" ]]; then
					if [ -f "$TS3_DIR/ts3server.ini" ]; then
						if [[ $Debug == "1" ]]; then
							echo ""
							echo "File ts3server.ini exist"
							echo ""
							su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start inifile=ts3server.ini"
						fi
					else
						su $TS3_USER -c "$TS3_DIR/ts3server_minimal_runscript.sh createinifile=1"
						su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh stop"
						sed -i "s@raw,ssh@$Query_protocols@g" $TS3_DIR/ts3server.ini
						sudo chown "$TS3_USER":"$TS3_USER" $TS3_DIR -R
						su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start inifile=ts3server.ini"
					fi
				else
					sudo chown "$TS3_USER":"$TS3_USER" "$TS3_DIR" -R
					echo "initiate server restart..."
					if nc -w $TIMEOUT -z $REMOTEHOST $ServerQuery; then
						echo "TeamSpeak3 server START"
					else
						su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start"
					fi
				fi
			fi
		fi
	fi
}

Install() {
	Download
	## TeamSpeak 3 server NOT EXIST
	if [[ $Debug == "1" ]]; then
			echo ""
			echo "$TS3_DIR is no exist"
			echo "Create DIR $TS3_DIR"
			echo ""
		fi
	mkdir -p $TS3_DIR
	## Create file license accepted
	touch $TS3_DIR/.ts3server_license_accepted
	## Test if download file compress exist
	if [ -f $TMP_DIR_DOWNLOAD/$TS3_FILE_COMPRESSED ]; then
		if [[ $Debug == "1" ]]; then
			echo ""
			echo "$TMP_DIR_DOWNLOAD/$TS3_FILE_COMPRESSED exist"
			echo ""
		fi
		## Extracting
		if [[ $Debug == "1" ]]; then
			echo ""
			echo "extracting..."
			echo ""
		fi
		tar -C $TMP_DIR_DOWNLOAD -xjf $TMP_DIR_DOWNLOAD/$TS3_FILE_COMPRESSED
		## Move new or update files in folder Teamspeak 3 server
		if [[ $Debug == "1" ]]; then
			echo ""
			echo "Move new or update files in folder Teamspeak 3 server..."
			echo ""
		fi
		rsync -a $TMP_DIR_DOWNLOAD/teamspeak3-server_linux_$TS3_ARCH_FILE/ $TS3_DIR/
		## Test if Type DataBase is MariaDB in option
		if [[ $Db_Type == "MariaDB" ]]; then
			ln -s $TS3_DIR/redist/libmariadb.so.2 $TS3_DIR/libmariadb.so.2
			ldd $TS3_DIR/libts3db_mariadb.so
		fi
		## Delete files compress and others
		if [[ $Debug == "1" ]]; then
			echo ""
			echo "Delete files compress and others ..."
			echo ""
		fi
		rm -rf $TMP_DIR_DOWNLOAD/*
		## Make scripts executable
		sudo chmod a+x $TS3_DIR/ts3server_startscript.sh
		sudo chmod a+x $TS3_DIR/ts3server_minimal_runscript.sh
		## Add rules firewall in system
		FirewallRules
		## Create service for start auto on start system
		CreateService
		## Check if ini file must be created
		if [[ $ByPassCheckIniFile == "0" ]]; then
			sudo chown "$TS3_USER":"$TS3_USER" $TS3_DIR -R
			if [[ $Debug == "1" ]]; then
			echo ""
			echo "Creating file inifile ..."
			echo ""
			fi
			su $TS3_USER -c "$TS3_DIR/ts3server_minimal_runscript.sh createinifile=1"
			su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh stop"
		else
			sudo chown "$TS3_USER":"$TS3_USER" "$TS3_DIR" -R
			if [[ $Debug == "1" ]]; then
			echo ""
			echo "Creating file inifile ..."
			echo ""
			fi
			su $TS3_USER -c "$TS3_DIR/ts3server_minimal_runscript.sh"
			sleep 2
			su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh stop"
			sleep 2
			su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start"
		fi
		echo "fin" &&>> test.log
	fi
}


if [[ -z "$1" ]]; then
	echo ""
	echo "ERROR!!! SCRIPT MUST BE RUN WITH 1 or 2 MINIMUM PARAMETERS"
	echo ""
	exit 1
else
	if [[ "$1" == start ]]; then
		sudo systemctl start teamspeak.service
		sleep 5
		if nc -w $TIMEOUT -z $REMOTEHOST $ServerQuery; then
			echo "TeamSpeak3 server START"
		else
			if [[ $ByPassCheckIniFile == "0" ]]; then
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start inifile=ts3server.ini"
			else
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start"
			fi
		fi
		echo "TeamSpeak3 server START succesfully"
		echo ""
		echo -e "Your servers external IP Address is: $PUBLIC_IP"
		echo ""
	fi
	if [[ "$1" == stop ]]; then
		sudo systemctl stop teamspeak.service
		sleep 3
		if nc -w $TIMEOUT -z $REMOTEHOST $ServerQuery; then
			su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh stop"
		else
			echo "TeamSpeak3 server STOP"
		fi
		echo "TeamSpeak3 server STOP succesfully"
		echo ""
		echo -e "Your servers external IP Address is: $PUBLIC_IP"
		echo ""
	fi
	if [[ "$1" == install ]]; then
		Install
		sudo sed -i "s@(raw,ssh)@$Query_protocols@g" $TS3_DIR/ts3server.ini
		sudo chown "$TS3_USER":"$TS3_USER" $TS3_DIR -R
		sleep 2
		sudo systemctl start teamspeak.service
		sleep 3
		if nc -w $TIMEOUT -z $REMOTEHOST $ServerQuery; then
			echo "TeamSpeak3 server START"
		else
			if [[ $ByPassCheckIniFile == "0" ]]; then
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start inifile=ts3server.ini"
			else
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start"
			fi
		fi
		echo "TeamSpeak3 INSTALL succesfully"
		echo ""
		echo -e "Your servers external IP Address is: $PUBLIC_IP"
		echo ""
	fi
	if [[ "$1" == update ]]; then
		Update
		sudo chown "$TS3_USER":"$TS3_USER" $TS3_DIR -R
		sleep 2
		sudo systemctl start teamspeak.service
		sleep 3
		if nc -w $TIMEOUT -z $REMOTEHOST $ServerQuery; then
			echo "TeamSpeak3 server START"
		else
			if [[ $ByPassCheckIniFile == "0" ]]; then
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start inifile=ts3server.ini"
			else
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start"
			fi
		fi
		echo "TeamSpeak3 UPDATE succesfully"
		echo ""
		echo -e "Your servers external IP Address is: $PUBLIC_IP"
		echo ""
	fi
	if [[ "$1" == createservice ]]; then
		CreateService
		echo ""
		echo "Service system create successfully"
		echo ""
		echo -e "Your servers external IP Address is: $PUBLIC_IP"
		echo ""
	fi
	if [[ "$1" == updatefirewallrules ]]; then
		FirewallRules
		echo ""
		echo "Rules firewall updated"
		echo ""
		echo -e "Your servers external IP Address is: $PUBLIC_IP"
		echo ""
	fi
	if [[ "$1" == updatepassword ]]; then
		if [[ -z "$2" ]]; then
			if [[ "$2" == "token" ]]; then
				# Here script create token by api"
				echo ""
				# echo ""
				# find $TS3_DIR/logs -name "*_1.log">TS3_File_Token.txt
				# TS3_File_Token=$(cat TS3_File_Token.txt)
				# sed -n -e 's/.*token=/Server Admin Token: /p' $TS3_File_Token
				# echo ""
			else
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh stop"
				su $TS3_USER -c "$TS3_DIR/ts3server_minimal_runscript.sh serveradmin_password=$2"
				su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh stop"
				if nc -w $TIMEOUT -z $REMOTEHOST $ServerQuery; then
					echo "TeamSpeak3 server START"
				else
					if [[ $ByPassCheckIniFile == "0" ]]; then
						su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start inifile=ts3server.ini"
						echo ""
						echo "Password UPDATE succesfully"
						echo ""
						echo "Username=serveradmin"
						echo "Password=$2"
						echo ""
						find $TS3_DIR/logs -name "*_1.log">TS3_File_Token.txt
						TS3_File_Token=$(cat TS3_File_Token.txt)
						sed -n -e 's/.*token=/Server Admin Token: /p' $TS3_File_Token
						echo ""
						echo -e "Your servers external IP Address is: $EXTERNAL_IP"
						echo ""
					else
						su $TS3_USER -c "$TS3_DIR/ts3server_startscript.sh start"
						echo ""
						echo "Password UPDATE succesfully"
						echo ""
						echo "Username=serveradmin"
						echo "Password=$2"
						echo ""
						find $TS3_DIR/logs -name "*_1.log">TS3_File_Token.txt
						TS3_File_Token=$(cat TS3_File_Token.txt)
						sed -n -e 's/.*token=/Server Admin Token: /p' $TS3_File_Token
						echo ""
						echo -e "Your servers external IP Address is: $EXTERNAL_IP"
						echo ""
					fi
				fi
			fi
		fi
	fi
fi
