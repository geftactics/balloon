#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Script must be run as root. Try 'sudo $0'"
  exit 1
fi

echo "Updating packages..."
apt-get update && apt-get -y upgrade

echo "Installing packages..."
apt-get -y install git libcurl4-openssl-dev libncurses5-dev ssdv wiringpi

echo "Enabling SPI..."
raspi-config nonint do_spi 0

echo "Setting hostname..."
raspi-config nonint do_hostname gateway

echo "Disabling bluetooth"
grep -qxF 'dtoverlay=pi3-disable-bt' /boot/config.txt || echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt
systemctl disable hciuart

echo "Installing lora-gateway..."
git clone https://github.com/PiInTheSky/lora-gateway.git /home/pi/lora-gateway
make -C /home/pi/lora-gateway/
cp -f $(dirname $0)/gateway.txt /home/pi/lora-gateway/gateway.txt
chown -R pi:pi /home/pi/lora-gateway/

echo "-------------------------------------"
echo " Installation complete - Reboot now!"
echo "-------------------------------------"
