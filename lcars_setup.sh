#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Script must be run as root. Try 'sudo $0'"
  exit 1
fi

echo "Updating packages..."
apt-get update && apt-get -y upgrade

echo "Installing packages..."
apt-get -y install git gpsd libcurl4-openssl-dev libncurses5-dev ssdv wiringpi

echo "Enabling SSH..."
raspi-config nonint do_ssh 0

echo "Enabling SPI..."
raspi-config nonint do_spi 0

echo "Enabling I2C..."
raspi-config nonint do_i2c 0

echo "Enabling serial..."
raspi-config nonint do_serial 2

echo "Disabling boot splash..."
raspi-config nonint do_boot_splash 1

echo "Setting hostname..."
raspi-config nonint do_hostname chase

echo "Disabling screen blanking..."
raspi-config nonint do_blanking 1

echo "Disabling bluetooth"
grep -qxF 'dtoverlay=pi3-disable-bt' /boot/config.txt || echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt
systemctl disable hciuart

echo "Installing lora-gateway..."
git clone https://github.com/PiInTheSky/lora-gateway.git /home/pi/lora-gateway
make -C /home/pi/lora-gateway/
cp -f $(dirname $0)/config/gateway.txt /home/pi/lora-gateway/gateway.txt
chown -R pi:pi /home/pi/lora-gateway/

echo "Installing LCARS..."
git clone https://github.com/PiInTheSky/lcars.git /home/pi/lcars
chmod +x /home/pi/lcars/lcars.sh
apt-get -y install gnuplot screen wmctrl xterm
sed -i 's/DEVICES=.*/DEVICES="\/dev\/ttyAMA0"/' /etc/default/gpsd
sed 's/SSDVPath/SSDV.Path/' /home/pi/lcars/lcars.py
cp -f $(dirname $0)/other/start_web /home/pi/lcars/start_web
chown -R pi:pi /home/pi/lcars
mkdir /home/pi/.fonts
cp -f $(dirname $0)/.fonts/*.ttf /home/pi/.fonts/
chown -R pi:pi /home/pi/.fonts
fc-cache -v -f
mkdir /home/pi/.config/autostart
cp -f $(dirname $0)/other/lcars.desktop /home/pi/.config/autostart/lcars.desktop
chmod +x /home/pi/.config/autostart/lcars.desktop
chown -R pi:pi /home/pi/.config/

echo "-------------------------------------"
echo " Installation complete - Reboot now!"
echo "-------------------------------------"

