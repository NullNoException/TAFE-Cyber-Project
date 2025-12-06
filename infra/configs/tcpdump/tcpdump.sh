#!/bin/sh
###############################################################################
# TCPDump Collector Script - Continuous packet capture for all networks
# Captures traffic on all interfaces and rotates PCAP files
###############################################################################

set -e

# Create PCAP directory if it doesn't exist
mkdir -p /pcap

# Configuration
PCAP_DIR="/pcap"
PCAP_FILE_SIZE=500  # 500MB per file
PCAP_KEEP_COUNT=10  # Keep last 10 files
RING_BUFFER=32      # Ring buffer size in MB
SNAPLEN=65535       # Snapshot length (full packets)
CAPTURE_FILTER=""   # Empty = capture all traffic

echo "[$(date)] Starting TCPDump packet collector..."

# Function to get all interface names
get_interfaces() {
    ip link show | grep "^[0-9]" | awk -F: '{print $2}' | tr -d ' ' | grep -v "^lo$"
}

# Display available interfaces
echo "[$(date)] Available interfaces for capture:"
get_interfaces | while read iface; do
    echo "[$(date)]   - $iface"
done

# Start continuous packet capture with rotation
# This captures on all interfaces simultaneously
echo "[$(date)] Starting continuous packet capture..."
echo "[$(date)] PCAP files will be stored in: $PCAP_DIR"
echo "[$(date)] File size limit: ${PCAP_FILE_SIZE}M per file"
echo "[$(date)] Keeping last $PCAP_KEEP_COUNT files"

# Capture all interfaces with automatic file rotation
tcpdump \
    -i any \
    -w "$PCAP_DIR/capture-%Y%m%d-%H%M%S.pcap" \
    -G 3600 \
    -C $PCAP_FILE_SIZE \
    -Z root \
    -s $SNAPLEN \
    "$CAPTURE_FILTER" 2>&1 | while IFS= read -r line; do
        echo "[$(date)] [tcpdump] $line"
    done &

TCPDUMP_PID=$!

# Function to rotate old files (keep only last N files)
rotate_files() {
    cd "$PCAP_DIR" 2>/dev/null || return
    # Count existing pcap files
    file_count=$(ls -1 capture-*.pcap 2>/dev/null | wc -l)

    if [ "$file_count" -gt "$PCAP_KEEP_COUNT" ]; then
        echo "[$(date)] Rotating PCAP files (keeping $PCAP_KEEP_COUNT, found $file_count)..."
        # Remove oldest files, keeping only the most recent
        ls -1t capture-*.pcap | tail -n +$((PCAP_KEEP_COUNT + 1)) | xargs rm -f
        echo "[$(date)] Old PCAP files removed"
    fi
}

# Monitor and rotate files every 5 minutes
while true; do
    sleep 300
    rotate_files

    # Check if tcpdump is still running
    if ! kill -0 $TCPDUMP_PID 2>/dev/null; then
        echo "[$(date)] ERROR: TCPDump process died unexpectedly!"
        exit 1
    fi
done

###############################################################################
# NOTES:
# - All interfaces: tcpdump -i any (captures all interfaces)
# - Specific interface: tcpdump -i eth0
# - File rotation: -G 3600 (rotate every hour) -C 500 (rotate at 500MB)
# - Snaplen: -s 65535 (capture full packets)
# - Filter examples:
#   * tcp port 22       (SSH traffic)
#   * dns               (DNS queries/responses)
#   * http              (HTTP traffic)
#   * tcp port 443      (HTTPS traffic)
#   * icmp              (Ping traffic)
#   * src 10.10.0.0/8   (Traffic from internal networks)
###############################################################################
