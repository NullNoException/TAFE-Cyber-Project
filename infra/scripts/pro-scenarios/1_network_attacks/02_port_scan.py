#!/usr/bin/env python3
"""
Scenario 2: Port Scanning (Network Reconnaissance)
- Difficulty: Beginner
- Detection: Suricata, Prometheus, Wazuh
- Expected Alert: Port scan detection, suspicious connection patterns
"""

import sys
import argparse
import logging
import socket
import time
from datetime import datetime
import threading

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PortScanScenario:
    def __init__(self, target, port_range=(1, 1024), timeout=2, threads=10, verbose=False):
        self.target = target
        self.port_range = port_range
        self.timeout = timeout
        self.threads = threads
        self.verbose = verbose
        self.open_ports = []
        self.scanned_ports = 0
        self.results = {
            'scenario': 'PORT_SCAN',
            'target': target,
            'ports_scanned': 0,
            'open_ports': [],
            'status': 'pending'
        }

    def scan_port(self, port):
        """Scan a single port"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.timeout)
            result = sock.connect_ex((self.target, port))
            sock.close()

            self.scanned_ports += 1

            if result == 0:
                self.open_ports.append(port)
                logger.info(f"[+] Port {port}: OPEN")
                return True
            elif self.verbose:
                logger.debug(f"[-] Port {port}: CLOSED")
        except socket.gaierror:
            logger.error(f"[-] Hostname could not be resolved: {self.target}")
        except socket.error:
            if self.verbose:
                logger.debug(f"[-] Could not connect to {self.target}:{port}")
        except Exception as e:
            if self.verbose:
                logger.warning(f"[-] Error scanning port {port}: {e}")

        return False

    def start_scan(self):
        """Start threaded port scan"""
        logger.info(f"[*] Starting Port Scan against {self.target}")
        logger.info(f"[*] Port Range: {self.port_range[0]}-{self.port_range[1]}")
        logger.info(f"[*] Threads: {self.threads}")

        start_time = time.time()
        port_list = list(range(self.port_range[0], self.port_range[1] + 1))

        # Create threads
        threads_list = []
        ports_per_thread = len(port_list) // self.threads

        for i in range(self.threads):
            start_port = i * ports_per_thread
            end_port = start_port + ports_per_thread if i < self.threads - 1 else len(port_list)

            thread = threading.Thread(
                target=self._scan_port_range,
                args=(port_list[start_port:end_port],)
            )
            thread.daemon = True
            thread.start()
            threads_list.append(thread)

        # Wait for all threads to complete
        for thread in threads_list:
            thread.join()

        elapsed = time.time() - start_time

        self.results['ports_scanned'] = self.scanned_ports
        self.results['open_ports'] = self.open_ports
        self.results['duration'] = elapsed
        self.results['status'] = 'completed'
        self.log_results()

    def _scan_port_range(self, ports):
        """Scan a range of ports"""
        for port in ports:
            self.scan_port(port)

    def log_results(self):
        """Log scan results"""
        logger.info("\n" + "="*60)
        logger.info("PORT SCAN RESULTS")
        logger.info("="*60)
        logger.info(f"Target: {self.target}")
        logger.info(f"Ports Scanned: {self.scanned_ports}")
        logger.info(f"Open Ports: {len(self.open_ports)}")
        if self.open_ports:
            logger.info(f"Open Port List: {sorted(self.open_ports)}")
        logger.info(f"Duration: {self.results.get('duration', 0):.2f}s")
        logger.info(f"Status: {self.results['status'].upper()}")
        logger.info("="*60)
        logger.info("\n[!] Check Monitoring Systems:")
        logger.info("  - Suricata: Look for port scan alerts")
        logger.info("  - Prometheus: Check tcp_connections by port")
        logger.info("  - Wazuh: Search for 'port scan' or 'reconnaissance'")
        logger.info("  - Netdata: Monitor connection patterns")
        logger.info("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description='Port Scanning Reconnaissance Scenario',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python 02_port_scan.py --target 10.10.10.10
  python 02_port_scan.py --target 192.168.1.100 --ports 1-65535 --threads 20 --verbose
        '''
    )

    parser.add_argument('--target', required=True, help='Target IP address or hostname')
    parser.add_argument('--ports', default='1-1024', help='Port range (default: 1-1024)')
    parser.add_argument('--timeout', type=int, default=2, help='Connection timeout in seconds')
    parser.add_argument('--threads', type=int, default=10, help='Number of threads (default: 10)')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose logging')

    args = parser.parse_args()

    # Parse port range
    try:
        port_parts = args.ports.split('-')
        if len(port_parts) != 2:
            raise ValueError("Port range format: start-end")
        start_port = int(port_parts[0])
        end_port = int(port_parts[1])
        if not (1 <= start_port <= 65535 and 1 <= end_port <= 65535 and start_port <= end_port):
            raise ValueError("Invalid port range")
    except ValueError as e:
        logger.error(f"[-] Invalid port range: {e}")
        sys.exit(1)

    # Run scenario
    scenario = PortScanScenario(
        target=args.target,
        port_range=(start_port, end_port),
        timeout=args.timeout,
        threads=args.threads,
        verbose=args.verbose
    )

    scenario.start_scan()

if __name__ == '__main__':
    main()
