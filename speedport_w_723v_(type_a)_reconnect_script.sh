#!/bin/sh
########################################################
# recon (c) Philipp Immel 2012 April 13 Version 1.1    #
########################################################	
# Description: Reconnects Speedport W 723V router
# Syntax: recon
# Extern: read printf echo curl grep awk sleep rm
########################################################

#----------------------
# Read router password
#----------------------
read -s -p "Password: " PASS
echo ""

#-------------------------------------
# Convert password to Base64 encoding
#-------------------------------------
BASE64PASS=$( printf "$PASS"|base64 )

#---------------------------
# Check external IP address
#---------------------------
echo "Fetching external IP address …"
OLDIP=$( curl -s http://checkip.dyndns.org | sed 's/[a-zA-Z/<> :]//g' )

#----------------------------------------------
# Log on to router and get a session ID cookie
#----------------------------------------------
echo "Logging in …"
curl --location --cookie-jar "SessionID.txt" --data "Username=admin&Password=$BASE64PASS" https://speedport.ip/index/login.cgi &> /dev/null

#----------------------------------------------
# Add comma to the cookie string for HTTP POST
#----------------------------------------------
echo "Preparing cookie …"
SIDCOOKIE=$( grep "SessionID" SessionID.txt | awk '{printf "%s,%s",$6,$7}' )

#-----------------------------
# Suspend internet connection
#-----------------------------
echo "Suspending internet connection …"
curl --location --cookie "SessionID.txt" --data "x.EnabledForInternet=0" https://speedport.ip/auth/setcfg.cgi?x=InternetGatewayDevice.WANDevice.1.WANCommonInterfaceConfig&cookie=$SIDCOOKIE &> /dev/null

#--------------------
# Wait for 5 seconds
#--------------------
sleep 5

#-----------------------------
# Release internet connection
#-----------------------------
echo "Releasing internet connection …"
curl --location --cookie "SessionID.txt" --data "x.EnabledForInternet=1" https://speedport.ip/auth/setcfg.cgi?x=InternetGatewayDevice.WANDevice.1.WANCommonInterfaceConfig&cookie=$SIDCOOKIE &> /dev/null

#-------------------------
# Log out from the router
#-------------------------
echo "Logging off …"
curl --location --cookie "SessionID.txt" --data "" https://speedport.ip/auth/logout.cgi?cookie=$SIDCOOKIE &> /dev/null

#---------------------------
# Check external IP address
#---------------------------
echo "Fetching external IP address …"
NEWIP=$( curl -s http://checkip.dyndns.org | sed 's/[a-zA-Z/<> :]//g' )

#-------------------
# Check for success
#-------------------
if [ "$OLDIP" != "$NEWIP" ]
then
    echo "Reconnect has been successful. Your new IP address is:" $NEWIP
else
	echo "Reconnect has not been successful. Please try again. Your IP address is still:" $OLDIP
fi

#--------------------
# Remove cookie file
#--------------------
rm SessionID.txt