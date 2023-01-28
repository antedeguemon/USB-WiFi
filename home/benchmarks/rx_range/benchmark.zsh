#!/bin/zsh
set -e 

# =========================
#  Configuration variables 
# =========================

INTERFACE="wlan1"
INTERVAL_SECONDS="30" # Interval between each channel switch

# ========================
#  RX benchmarking script
# ========================

function start_monitor_mode {
  sudo ifconfig $INTERFACE down
  sudo iw dev $INTERFACE set power_save off
  sudo iw dev $INTERFACE set monitor control otherbss
  sudo ifconfig $INTERFACE up
}

function switch_channel {
	sudo ifconfig 
	sudo iw dev $INTERFACE set channel $1
}

start_monitor_mode;
switch_channel 1;
