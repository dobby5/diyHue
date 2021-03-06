#!/bin/bash

### Choose Branch for Install
echo -e "\033[36mPlease choose a Branch to install\033[0m"
echo -e "\033[33mSelect Branch by entering the corresponding Number: [Default: Master]\033[0m  "
echo -e "[1] Master Branch - most stable Release "
echo -e "[2] Developer Branch - test latest features and fixes - Work in Progress!"
echo -e "\033[36mNote: Please report any Bugs or Errors with Logs to our GitHub, Discourse or Slack. Thank you!\033[0m"
echo -n "I go with Nr.: "

branchSelection=""
read userSelection
case $userSelection in
        1)
        branchSelection="master"
        echo -e "Master selected"
        ;;
        2)
        branchSelection="dev"
        echo -e "Dev selected"
        ;;
				*)
        branchSelection="master"
        echo -e "Master selected"
        ;;
esac

echo -e "\033[32m Deleting folders.\033[0m"
rm -Rf /opt/hue-emulator
echo -e "\033[32m Updating repository.\033[0m"
opkg update
wait
echo -e "\033[32m Installing dependencies.\033[0m"
opkg install ca-bundle git git-http nano nmap python3 python3-pip python3-setuptools
wait
opkg install curl coap-client unzip coreutils-nohup openssl-util
wait
opkg install python3-requests python3-astral python3-pytz python3-paho-mqtt
wait
echo -e "\033[32m Creating directories.\033[0m"
mkdir /opt
mkdir /opt/tmp
mkdir /opt/hue-emulator
echo -e "\033[32m Updating python3-pip.\033[0m"
python3 -m pip install --upgrade pip
wait
echo -e "\033[32m Installing pip dependencies.\033[0m"
python3 -m pip install ws4py zeroconf
wait
cd /opt/tmp
echo -e "\033[32m Downloading diyHue.\033[0m"
wget -q https://github.com/diyhue/diyHue/archive/$branchSelection.zip -O diyHue.zip
echo -e "\033[32m Unzip diyHue.\033[0m"
unzip -q -o  diyHue.zip
wait
echo -e "\033[32m Copying unzip files to directories.\033[0m"
cd /opt/tmp/diyHue-$branchSelection/BridgeEmulator
cp HueEmulator3.py updater /opt/hue-emulator/
cp default-config.json /opt/hue-emulator/config.json
cp default-config.json /opt/hue-emulator/default-config.json
cp -r debug functions protocols web-ui /opt/hue-emulator/
echo -e "\033[32m Detecting processor architecture.\033[0m"
wait
arch=`uname -m`
wait
echo -e "\033[32m Architecture detected: $arch\033[0m"
echo -e "\033[32m Copying binary $arch for Openwrt.\033[0m"
cp entertainment-openwrt-$arch /opt/hue-emulator/entertain-srv
echo -e "\033[32m Copying custom network function for openwrt.\033[0m"
rm -Rf /opt/hue-emulator/functions/network.py
mv /opt/hue-emulator/functions/network_OpenWrt.py /opt/hue-emulator/functions/network.py
wait
echo -e "\033[32m Copying startup service.\033[0m"
cp diyHueWrt-service /etc/init.d/
echo -e "\033[32m Generating certificate.\033[0m"
#mac=`cat /sys/class/net/$(ip route get 8.8.8.8 | sed -n 's/.* dev \([^ ]*\).*/\1/p')/address`
mac=`cat /sys/class/net/br-lan/address`
curl https://raw.githubusercontent.com/mariusmotea/diyHue/9ceed19b4211aa85a90fac9ea6d45cfeb746c9dd/BridgeEmulator/openssl.conf -o openssl.conf
wait
serial="${mac:0:2}${mac:3:2}${mac:6:2}fffe${mac:9:2}${mac:12:2}${mac:15:2}"
dec_serial=`python3 -c "print(int(\"$serial\", 16))"`
openssl req -new -days 3650 -config openssl.conf -nodes -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -pkeyopt ec_param_enc:named_curve -subj "/C=NL/O=Philips Hue/CN=$serial" -keyout private.key -out public.crt -set_serial $dec_serial
wait
touch /opt/hue-emulator/cert.pem
cat private.key > /opt/hue-emulator/cert.pem
cat public.crt >> /opt/hue-emulator/cert.pem
rm private.key public.crt
echo -e "\033[32m Changing permissions.\033[0m"
chmod +x /etc/init.d/diyHueWrt-service
chmod +x /opt/hue-emulator/HueEmulator3.py
chmod +x /opt/hue-emulator/debug
chmod +x /opt/hue-emulator/protocols
chmod +x /opt/hue-emulator/updater
chmod +x /opt/hue-emulator/web-ui
chmod +x /opt/hue-emulator/functions
chmod +x /opt/hue-emulator/config.json
chmod +x /opt/hue-emulator/default-config.json
chmod +x /opt/hue-emulator/entertain-srv
chmod +x /opt/hue-emulator/functions/network.py
chmod +x /opt/hue-emulator
echo -e "\033[32m Enable startup service.\033[0m"
/etc/init.d/diyHueWrt-service enable
wait
echo -e "\033[32m modify http port 80 to 82: list listen_http 0.0.0.0:82, list listen_http [::]: 82 and server.port = 82.\033[0m"
echo -e "\033[32m To save the changes you've made, press CTRL + O. To exit nano, press CTRL + X.\033[0m"
sleep 20s
nano /etc/config/uhttpd
wait
nano /etc/lighttpd/lighttpd.conf
echo -e "\033[32m Installation completed.\033[0m"
rm -Rf /opt/tmp
echo -e "\033[32m Restarting...\033[0m"
wait
reboot 10
exit 0
