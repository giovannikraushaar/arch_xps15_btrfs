#!/bin/bash
brightness=$(cat /sys/class/backlight/intel_backlight/brightness) 

echo $brightness



if (($brightness <=120000 )); then
	let brightness=$brightness-10000
fi

if (($brightness <7000)); then
	  let brightness=10000;
fi
echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo bash

