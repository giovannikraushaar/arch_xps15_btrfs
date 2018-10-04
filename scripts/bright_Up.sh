#!/bin/bash
brightness=$(cat /sys/class/backlight/intel_backlight/brightness) 

if (($brightness >0)); then
  let brightness=$brightness+10000;
fi
if (($brightness >=120000)); then
	let brightness=120000;
fi
echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo bash
