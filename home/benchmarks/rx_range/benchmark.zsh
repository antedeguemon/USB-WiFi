#!/bin/zsh

if [ $# -ne 2 ]; then
  echo "Usage: benchmark.sh <interface> <label>"
  exit 1
fi

# =========================
#  Configuration variables
# =========================

INTERFACE=$1
LABEL=$2
CHANNEL_SWITCH_SECONDS=30
CHANNELS=(1 6 11)
CAPTURES_DIR_PREFIX="captures"

# Filters only for beacons from APs
TCPDUMP_FILTER="type mgt"

# ========================
#  RX benchmarking script
# ========================

function start_monitor_mode() {
  echo "Disabling interface"
  sudo ifconfig $INTERFACE down

  echo "Changing device region"
  sudo iw reg set BZ

  echo "Enabling promisc mode"
  sudo ifconfig $INTERFACE promisc

  echo "Setting tx power to 30mBm"
  sudo iw dev $1 set txpower fixed 30mBm

  echo "Disabling power management"
  sudo iw dev $INTERFACE set power_save off

  echo "Enabling monitor mode"
  sudo iw dev $INTERFACE set monitor control otherbss

  echo "Enabling interface"
  sudo ifconfig $INTERFACE up
}

function switch_channel() {
  sudo iw dev $INTERFACE set channel $1
}

echo "Enabling monitor mode for $INTERFACE"
start_monitor_mode

echo ""

OUTPUT_FILE="$LABEL.csv"
CURRENT_DIR=$(pwd)
CAPTURES_DIR="${CAPTURES_DIR_PREFIX}_${LABEL}"

rm -rf $CAPTURES_DIR
mkdir -p $CAPTURES_DIR && cd $CAPTURES_DIR
rm -rf total_results.txt # clears previous results

for CHANNEL in "${CHANNELS[@]}"; do
  echo "=== Switching to channel $CHANNEL ==="
  switch_channel $CHANNEL
  STATS_FILE="results_$CHANNEL.txt"
  CAPTURE_FILE="capture_$CHANNEL.pcap"

  echo "Starting tcpdump..."
  sudo timeout ${CHANNEL_SWITCH_SECONDS}s tcpdump -i $INTERFACE -w $CAPTURE_FILE $TCPDUMP_FILTER

  echo "Filtering results..."
  tshark -r $CAPTURE_FILE -T fields -E separator=";" -Y "wlan_radio.channel == $CHANNEL and wlan.sa == wlan.ta" -e wlan.bssid -e wlan.ssid -e wlan_radio.signal_dbm -e wlan_radio.channel >$STATS_FILE

  CHANNEL_COUNT=$(cat ${STATS_FILE} | cut -d ";" -f1 | wc -l)
  CHANNEL_MACS=$(cat ${STATS_FILE} | cut -d ";" -f1 | sort | uniq | grep -c '^[^#]')

  echo ""
  echo "\tStatistics for channel $CHANNEL:"
  echo "\tSeen packets: $CHANNEL_COUNT"
  echo "\tNumber of seen BSSIDs: $CHANNEL_MACS"
  echo "" 

  cat $STATS_FILE >>total_results.txt
done

TOTAL_COUNT=$(cat total_results.txt | wc -l)
TOTAL_MACS=$(sort total_results.txt | cut -d ";" -f1 | uniq | grep -c '^[^#]')
TOTAL_TIME=$((${#CHANNELS[@]} * $CHANNEL_SWITCH_SECONDS))

CSV_HEADER="BSSID;SSID;CH;Pwr;No."
CSV_ROWS=$(cat total_results.txt | sort | datamash -t";" groupby 1 last 2 last 4 mean 3 count 1 | sort -n -r -t";" -k 4)
CSV_CONTENT="$CSV_HEADER\n$CSV_ROWS"

echo "=== FINAL RESULTS ==="
echo ""
echo "BSSID / Signal average:"
echo -e "$CSV_CONTENT" | column -t -s";"
echo ""
echo "Statistics:"
echo "Time monitored: $TOTAL_TIME seconds"
echo "Seen packets: $TOTAL_COUNT"
echo "Unique BSSIDs: $TOTAL_MACS"
echo ""

cd $CURRENT_DIR

echo -e "$CSV_CONTENT" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Time monitored: $TOTAL_TIME seconds" >> $OUTPUT_FILE
echo "Seen packets: $TOTAL_COUNT" >> $OUTPUT_FILE
echo "Unique BSSIDs: $TOTAL_MACS" >> $OUTPUT_FILE

echo "Output saved to $OUTPUT_FILE"
