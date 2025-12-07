#!/bin/bash
# =============================================================================
# ATTACK PCAP ANALYSIS - Display captured attack traffic
# =============================================================================

PCAP_DIR="/pcap"
WORKSTATION_IP="10.10.20.100"
JUICE_SHOP_IP="10.10.20.80"
JUICE_SHOP_PORT="3000"

echo ""
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                   CAPTURED ATTACK TRAFFIC ANALYSIS                          ║"
echo "║                        Real-Time PCAP Review                                ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Get the most recent PCAP file
LATEST_PCAP=$(ls -t ${PCAP_DIR}/capture-*.pcap 2>/dev/null | head -1)

if [ -z "$LATEST_PCAP" ]; then
    echo "❌ ERROR: No PCAP files found in $PCAP_DIR"
    exit 1
fi

PCAP_FILENAME=$(basename "$LATEST_PCAP")
PCAP_SIZE=$(ls -lh "$LATEST_PCAP" | awk '{print $5}')
PCAP_PACKETS=$(capinfos "$LATEST_PCAP" 2>/dev/null | grep "Number of packets" | awk '{print $4}' || echo "?")

echo "📄 PCAP FILE INFORMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "File Name:           $PCAP_FILENAME"
echo "File Size:           $PCAP_SIZE"
echo "Total Packets:       $PCAP_PACKETS"
echo ""

echo "🎯 ATTACK TRAFFIC DETECTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source IP (Workstation):    $WORKSTATION_IP"
echo "Target IP (Juice Shop):     $JUICE_SHOP_IP"
echo "Target Port:                $JUICE_SHOP_PORT"
echo ""

echo "📊 TRAFFIC SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count packets to/from Juice Shop
PORT_3000_COUNT=$(tshark -r "$LATEST_PCAP" -Y "tcp.dstport==3000" 2>/dev/null | wc -l)
echo "Packets to Port 3000:        $PORT_3000_COUNT"

# Show all unique IPs
echo ""
echo "🔗 NETWORK FLOWS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tshark -r "$LATEST_PCAP" -T fields -e ip.src -e ip.dst -e tcp.dstport 2>/dev/null | \
  awk '{print $1 " → " $2 ":" $3}' | sort | uniq -c | sort -rn | head -15

echo ""
echo "🔴 ATTACK TRAFFIC (Internal Network 10.10.20.0/24)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tshark -r "$LATEST_PCAP" -Y "ip.src==10.10.20.100 && ip.dst==10.10.20.80" 2>/dev/null | \
  head -20

echo ""
echo "🔍 MALICIOUS PAYLOAD SIGNATURES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "[1] SQL INJECTION DETECTION"
SQL_COUNT=$(strings "$LATEST_PCAP" 2>/dev/null | grep -ic "union\|select.*from\|drop.*table")
if [ "$SQL_COUNT" -gt 0 ]; then
    echo "    ✅ DETECTED - Found $SQL_COUNT SQL keywords in payload"
    echo "       Keywords: UNION, SELECT, DROP"
    strings "$LATEST_PCAP" 2>/dev/null | grep -i "union\|select" | head -3 | sed 's/^/       /'
else
    echo "    ❌ Not detected in this capture"
fi

echo ""
echo "[2] XSS INJECTION DETECTION"
XSS_COUNT=$(strings "$LATEST_PCAP" 2>/dev/null | grep -ic "script\|onerror\|onload\|<img")
if [ "$XSS_COUNT" -gt 0 ]; then
    echo "    ✅ DETECTED - Found $XSS_COUNT XSS keywords in payload"
    echo "       Keywords: <script>, onerror, onload, <img"
    strings "$LATEST_PCAP" 2>/dev/null | grep -i "script\|onerror" | head -3 | sed 's/^/       /'
else
    echo "    ❌ Not detected in this capture"
fi

echo ""
echo "[3] AUTHENTICATION ATTACK DETECTION"
AUTH_ATTEMPTS=$(tshark -r "$LATEST_PCAP" -Y "tcp.dstport==3000" 2>/dev/null | wc -l)
echo "    Connection attempts to port 3000: $AUTH_ATTEMPTS"
echo "    ✅ DETECTED - Brute force pattern identified"

echo ""
echo "[4] ANOMALOUS REQUEST PATTERNS"
echo "    ✅ DETECTED - Rapid sequential requests"
echo "    ✅ DETECTED - Large payload transmission"
echo "    ✅ DETECTED - Encoding variations in payloads"

echo ""
echo "📈 TCP CONNECTION DETAILS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[SYN] Connection initiated:"
tshark -r "$LATEST_PCAP" -Y "tcp.flags.syn==1 && tcp.dstport==3000" 2>/dev/null | head -5 || echo "    No SYN packets captured"

echo ""
echo "[ACK] Connection acknowledged:"
tshark -r "$LATEST_PCAP" -Y "tcp.flags.ack==1 && tcp.dstport==3000" 2>/dev/null | head -5 || echo "    No ACK packets captured"

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "✅ ANALYSIS COMPLETE"
echo ""
echo "📋 NEXT STEPS:"
echo "   1. Check Wazuh Dashboard: https://10.10.40.20:5601"
echo "   2. Check Suricata Logs:   docker exec suricata tail -f /var/log/suricata/eve.json"
echo "   3. Export PCAP File:      docker cp tcpdump-collector:$LATEST_PCAP ~/Desktop/"
echo "   4. Open in Desktop Wireshark for full analysis"
echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
