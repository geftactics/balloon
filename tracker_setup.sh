#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Script must be run as root. Try 'sudo $0'"
  exit 1
fi

echo "Updating packages..."
apt-get update && apt-get -y upgrade

echo "Installing packages..."
apt-get -y install fswebcam git python3-distutils ssdv wiringpi

echo "Building pigpio..."
wget https://github.com/joan2937/pigpio/archive/master.zip -q --show-progress -O /tmp/pigpio.zip
unzip -q /tmp/pigpio.zip -d /tmp
make -C /tmp/pigpio-master/
make install -C /tmp/pigpio-master/
rm -rf /tmp/pigpio-master
rm /tmp/pigpio.zip

echo "Enabling camera..."
raspi-config nonint do_camera 0

echo "Enabling SPI..."
raspi-config nonint do_spi 0

echo "Enabling I2C..."
raspi-config nonint do_i2c 0

echo "Enabling serial..."
raspi-config nonint do_serial 2

echo "Enabling 1-Wire..."
raspi-config nonint do_onewire 0

echo "Setting hostname..."
raspi-config nonint do_hostname tracker

echo "Disabling bluetooth"
grep -qxF 'dtoverlay=pi3-disable-bt' /boot/config.txt || echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt
systemctl disable hciuart

echo "Installing PITS..."
git clone https://github.com/PiInTheSky/pits.git /home/pi/pits
make -C /home/pi/pits/tracker/
cp -f /home/pi/pits/boot/pisky.txt /boot
cp -f /home/pi/pits/systemd/tracker.service /lib/systemd/system
systemctl enable tracker.service

echo "-------------------------------------"
echo " Installation complete - Reboot now!"
echo "-------------------------------------"
