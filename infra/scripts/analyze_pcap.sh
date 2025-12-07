#!/bin/bash
# PCAP Analysis Script - Extract Attack Traffic from Captured Packets

PCAP_FILE="/pcap/capture-20251207-115603.pcap"
WORKSTATION_IP="10.10.20.100"
JUICE_SHOP_IP="10.10.20.80"
JUICE_SHOP_PORT="3000"

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║                    WIRESHARK PCAP ANALYSIS REPORT                          ║"
echo "║                   Attack Traffic from Docker Network                        ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "📊 PCAP FILE INFORMATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
capinfos "$PCAP_FILE" 2>/dev/null || ls -lh "$PCAP_FILE"
echo ""

echo "🔍 TRAFFIC SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source IP (Attack): $WORKSTATION_IP"
echo "Target IP (Juice Shop): $JUICE_SHOP_IP"
echo "Target Port: $JUICE_SHOP_PORT"
echo ""

echo "📈 TOTAL PACKETS ON PORT 3000:"
tshark -r "$PCAP_FILE" -Y "tcp.port==3000" 2>/dev/null | wc -l
echo ""

echo "🔴 TCP CONNECTION SETUP (SYN packets):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tshark -r "$PCAP_FILE" -Y "tcp.flags.syn==1 && tcp.port==3000" 2>/dev/null | head -10
echo ""

echo "📨 HTTP GET REQUESTS (XSS Attack Detection):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tshark -r "$PCAP_FILE" -Y "http.request.method==GET && tcp.port==3000" 2>/dev/null | head -15
echo ""

echo "📮 HTTP POST REQUESTS (SQL Injection/Brute Force Detection):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tshark -r "$PCAP_FILE" -Y "http.request.method==POST && tcp.port==3000" 2>/dev/null | head -15
echo ""

echo "🎯 HTTP REQUEST DETAILS WITH PAYLOADS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tshark -r "$PCAP_FILE" -Y "http.request && tcp.port==3000" -x 2>/dev/null | head -100
echo ""

echo "⚠️  SUSPICIOUS PATTERNS IN CAPTURED TRAFFIC:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "[1] SQL Injection Keywords:"
tshark -r "$PCAP_FILE" -Y "tcp.port==3000 && tcp.payload contains \"UNION\"" 2>/dev/null && echo "    ✓ UNION keyword detected" || echo "    - No UNION keyword found"
tshark -r "$PCAP_FILE" -Y "tcp.port==3000 && tcp.payload contains \"SELECT\"" 2>/dev/null && echo "    ✓ SELECT keyword detected" || echo "    - No SELECT keyword found"
tshark -r "$PCAP_FILE" -Y "tcp.port==3000 && tcp.payload contains \"DROP\"" 2>/dev/null && echo "    ✓ DROP keyword detected" || echo "    - No DROP keyword found"
echo ""

echo "[2] XSS Injection Patterns:"
tshark -r "$PCAP_FILE" -Y "tcp.port==3000 && tcp.payload contains \"script\"" 2>/dev/null && echo "    ✓ <script> tag detected" || echo "    - No <script> tag found"
tshark -r "$PCAP_FILE" -Y "tcp.port==3000 && tcp.payload contains \"onerror\"" 2>/dev/null && echo "    ✓ onerror handler detected" || echo "    - No onerror handler found"
tshark -r "$PCAP_FILE" -Y "tcp.port==3000 && tcp.payload contains \"onload\"" 2>/dev/null && echo "    ✓ onload handler detected" || echo "    - No onload handler found"
echo ""

echo "[3] Brute Force Patterns:"
tshark -r "$PCAP_FILE" -Y "http.response.code==401 && tcp.port==3000" 2>/dev/null | wc -l | xargs echo "    Found 401 Unauthorized responses:"
tshark -r "$PCAP_FILE" -Y "http.response.code==500 && tcp.port==3000" 2>/dev/null | wc -l | xargs echo "    Found 500 Server Error responses:"
echo ""

echo "═══════════════════════════════════════════════════════════════════════════════"
echo "✅ PCAP Analysis Complete"
echo "═══════════════════════════════════════════════════════════════════════════════"
