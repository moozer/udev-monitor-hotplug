#!/bin/bash

output_status() {
	logger "$1"
	notify-send "$1"
	echo "$1"
}

output_status "Monitor connected/disconnected"
#Adapt this script to your needs.

DEVICES=$(find /sys/class/drm/*/status)

#inspired by /etc/acpd/lid.sh and the function it sources

displaynum=`ls /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##`
if echo $displaynum | grep " " > /dev/null; then
	output_status "Warning: multiple displays found, using first: $displaynum"
	displaynum=`echo $displaynum | cut -d ' ' -f1`
fi

display=":$displaynum.0"
export DISPLAY=":$displaynum.0"

output_status "Using DISPLAY $DISPLAY"


# we don't have "consolekit installed"
#uid=$(ck-list-sessions | awk 'BEGIN { unix_user = ""; } /^Session/ { unix_user = ""; } /unix-user =/ { gsub(/'\''/,"",$3); unix_user = $3; } /x11-display = '\'$display\''/ { print unix_user; exit (0); }')
#if [ -n "$uid" ]; then
#	# from https://wiki.archlinux.org/index.php/Acpid#Laptop_Monitor_Power_Off
#	export XAUTHORITY=$(ps -C Xorg -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')
#else
#  echo "unable to find an X session"
#  exit 1
#fi
export XAUTHORITY=$(ps -C Xorg -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')


#this while loop declare the $HDMI1 $VGA1 $LVDS1 and others if they are plugged in
while read l
do
  dir=$(dirname $l);
  status=$(cat $l);
  dev=$(echo $dir | cut -d\- -f 2-);
	echo "Found $dev"

  if [ $(expr match  $dev "HDMI") != "0" ]
  then
#REMOVE THE -X- part from HDMI-X-n
    dev=HDMI${dev#HDMI-?-}
  else
    dev=$(echo $dev | tr -d '-')
  fi

  if [ "connected" == "$status" ]
  then
    output_status "$dev connected"
    declare $dev="yes";

  fi
done <<< "$DEVICES"


if [ ! -z "$HDMI1" -a ! -z "$VGA1" ]
then
  output_status "HDMI1 and VGA1 are plugged in"
  xrandr --output LVDS-1 --mode 1366x768 --primary
  xrandr --output  VGA-1  --auto --noprimary --right-of LVDS-1
  xrandr --output HDMI-1 --auto --noprimary --left-of LVDS-1
elif [ ! -z "$HDMI1" -a -z "$VGA1" ]; then
  output_status "HDMI1 is plugged in, but not VGA1"
  xrandr --output LVDS-1 --mode 1366x768 --noprimary
  xrandr --output  VGA-1 --off
  xrandr --output HDMI-1 --auto --primary --left-of LVDS-1
elif [ ! -z "$HDMI2" -a -z "$VGA1" ]; then
  output_status "HDMI2 is plugged in, but not VGA1"
  xrandr --output LVDS-1 --mode 1366x768 --noprimary
  xrandr --output  VGA-1 --off
  xrandr --output HDMI-2 --auto --primary --left-of LVDS-1
elif [ -z "$HDMI1" -a ! -z "$VGA1" ]; then
  output_status "VGA1 is plugged in, but not HDMI1"
  xrandr --output LVDS-1 --mode 1366x768 --noprimary
  xrandr --output HDMI-1 --off
  xrandr --output  VGA-1 --auto --primary --left-of LVDS-1
elif [ ! -z "$DP3" ]; then
  output_status "DP3 is plugged in"
  xrandr --output LVDS-1 --mode 1366x768 --noprimary
  xrandr --output HDMI-1 --off
  xrandr --output  VGA-1 --off
  xrandr --output   DP-3 --auto --primary --left-of LVDS-1
else
  output_status "No external monitors are plugged in"
  xrandr --output  VGA-1 --off
  xrandr --output HDMI-1 --off
  xrandr --output LVDS-1 --mode 1366x768 --primary
fi
