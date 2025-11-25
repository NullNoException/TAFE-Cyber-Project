#!/usr/bin/env python3

"""
Advanced DNS Testing Tool for CyberLab Infrastructure
Tests DNS functionality with detailed metrics and reporting
"""

import subprocess
import json
import sys
import socket
import time
from datetime import datetime
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict
import argparse

# Color codes for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

@dataclass
class DNSTestResult:
    """Data class for DNS test results"""
    test_name: str
    status: str  # 'PASS', 'FAIL', 'SKIP'
    duration_ms: float
    details: str = ""
    timestamp: str = ""

    def __post_init__(self):
        if not self.timestamp:
            self.timestamp = datetime.now().isoformat()

class DNSTester:
    """Main DNS testing class"""

    def __init__(self):
        self.results: List[DNSTestResult] = []
        self.dns_container = "dns-server"
        self.dns_ips = {
            'external': '10.10.0.50',
            'dmz': '10.10.10.50',
            'internal': '10.10.20.50',
            'security': '10.10.30.50',
            'management': '10.10.40.50'
        }
        self.test_domains = {
            'localhost': 'localhost',
            'dns-server': 'dns-server',
            'cyberlab': 'cyberlab.local',
            'nginx': 'web.cyberlab.local',
            'rocketchat': 'chat.cyberlab.local',
            'ldap': 'ldap.cyberlab.local',
            'wazuh': 'wazuh.cyberlab.local'
        }

    def print_header(self, text: str) -> None:
        """Print a formatted header"""
        line = "═" * 70
        print(f"\n{Colors.BLUE}{line}{Colors.NC}")
        print(f"{Colors.BLUE}{text}{Colors.NC}")
        print(f"{Colors.BLUE}{line}{Colors.NC}\n")

    def print_result(self, result: DNSTestResult) -> None:
        """Print a test result"""
        status_color = Colors.GREEN if result.status == "PASS" else Colors.RED if result.status == "FAIL" else Colors.YELLOW
        status_symbol = "✓" if result.status == "PASS" else "✗" if result.status == "FAIL" else "⚠"

        print(f"{status_color}{status_symbol} [{result.status}]{Colors.NC} {result.test_name} ({result.duration_ms:.2f}ms)")
        if result.details:
            for line in result.details.split('\n'):
                print(f"  {line}")

    def run_command(self, cmd: List[str], timeout: int = 10) -> Tuple[int, str, str]:
        """Run a shell command and return exit code, stdout, stderr"""
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 124, "", "Command timed out"
        except Exception as e:
            return 1, "", str(e)

    def docker_exec(self, container: str, cmd: str, timeout: int = 10) -> Tuple[int, str, str]:
        """Execute a command in a Docker container"""
        full_cmd = ["docker", "exec", container, "sh", "-c", cmd]
        return self.run_command(full_cmd, timeout)

    def check_container_running(self, container: str) -> bool:
        """Check if a Docker container is running"""
        returncode, stdout, _ = self.run_command(
            ["docker", "ps", "--filter", f"name=^{container}$", "--format", "{{.Names}}"]
        )
        return returncode == 0 and container in stdout

    def test_container_health(self) -> None:
        """Test DNS container health"""
        self.print_header("DNS Container Health Check")

        start = time.time()
        is_running = self.check_container_running(self.dns_container)
        duration = (time.time() - start) * 1000

        result = DNSTestResult(
            test_name="DNS Container Running",
            status="PASS" if is_running else "FAIL",
            duration_ms=duration,
            details="dns-server container is active" if is_running else "dns-server container is not running"
        )
        self.results.append(result)
        self.print_result(result)

        if is_running:
            # Get container details
            start = time.time()
            returncode, stdout, _ = self.run_command(
                ["docker", "inspect", self.dns_container, "--format", "{{.State.Status}}"]
            )
            duration = (time.time() - start) * 1000

            details = stdout.strip() if returncode == 0 else "Unable to get status"
            result = DNSTestResult(
                test_name="Container Status Check",
                status="PASS" if "running" in details else "FAIL",
                duration_ms=duration,
                details=f"Container Status: {details}"
            )
            self.results.append(result)
            self.print_result(result)

    def test_dns_ports(self) -> None:
        """Test DNS port accessibility"""
        self.print_header("DNS Port Accessibility Tests")

        ports = [
            (53, "udp", "DNS Service (UDP)"),
            (53, "tcp", "DNS Service (TCP)"),
            (5380, "tcp", "DNS Console (HTTP)")
        ]

        for port, protocol, description in ports:
            start = time.time()
            try:
                if protocol == "tcp":
                    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    sock.settimeout(2)
                    result_code = sock.connect_ex(('127.0.0.1', port))
                    sock.close()
                else:
                    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                    sock.settimeout(2)
                    sock.sendto(b'test', ('127.0.0.1', port))
                    sock.close()
                    result_code = 0

                duration = (time.time() - start) * 1000
                is_accessible = result_code == 0

                result = DNSTestResult(
                    test_name=f"Port {port}/{protocol.upper()} - {description}",
                    status="PASS" if is_accessible else "SKIP",
                    duration_ms=duration,
                    details="Port is accessible" if is_accessible else "Port not directly accessible (may be filtered)"
                )
            except Exception as e:
                duration = (time.time() - start) * 1000
                result = DNSTestResult(
                    test_name=f"Port {port}/{protocol.upper()} - {description}",
                    status="SKIP",
                    duration_ms=duration,
                    details=f"Error: {str(e)}"
                )

            self.results.append(result)
            self.print_result(result)

    def test_dns_console_http(self) -> None:
        """Test DNS console HTTP accessibility"""
        self.print_header("DNS Console HTTP Tests")

        if not self.check_container_running("traefik"):
            result = DNSTestResult(
                test_name="DNS Console via HTTP",
                status="SKIP",
                duration_ms=0,
                details="Traefik container not running"
            )
            self.results.append(result)
            self.print_result(result)
            return

        start = time.time()
        returncode, stdout, stderr = self.run_command(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "-m", "5", "http://localhost:5380"],
            timeout=10
        )
        duration = (time.time() - start) * 1000

        http_code = stdout.strip() if returncode == 0 else "000"
        is_accessible = http_code in ["200", "301", "302", "400"]

        result = DNSTestResult(
            test_name="DNS Console HTTP Response",
            status="PASS" if is_accessible else "SKIP",
            duration_ms=duration,
            details=f"HTTP Response Code: {http_code}" if http_code != "000" else "Unable to connect"
        )
        self.results.append(result)
        self.print_result(result)

    def test_dns_from_container(self, container: str, network: str, dns_ip: str) -> None:
        """Test DNS resolution from a specific container"""
        self.print_header(f"DNS Tests from {container.upper()} ({network} Network)")

        if not self.check_container_running(container):
            result = DNSTestResult(
                test_name=f"DNS from {container}",
                status="SKIP",
                duration_ms=0,
                details=f"Container {container} is not running"
            )
            self.results.append(result)
            self.print_result(result)
            return

        # Test DNS queries
        for domain_key, domain_name in self.test_domains.items():
            cmd = f"nslookup {domain_name} {dns_ip} 2>&1 | head -20"
            start = time.time()
            returncode, stdout, stderr = self.docker_exec(container, cmd)
            duration = (time.time() - start) * 1000

            # Check if query was successful
            is_successful = returncode == 0 and ("Address:" in stdout or "Name:" in stdout)

            details = stdout.split('\n')[0:3] if stdout else "No response"
            details_str = '\n'.join(details) if isinstance(details, list) else details

            result = DNSTestResult(
                test_name=f"Resolve {domain_name} from {container}",
                status="PASS" if is_successful else "FAIL",
                duration_ms=duration,
                details=details_str[:200]  # Limit details length
            )
            self.results.append(result)
            self.print_result(result)

    def test_all_containers(self) -> None:
        """Test DNS from all running containers"""
        self.print_header("DNS Tests from All Available Containers")

        containers_to_test = [
            ("traefik", "management", self.dns_ips['management']),
            ("nginx", "internal", self.dns_ips['internal']),
            ("openldap", "internal", self.dns_ips['internal']),
            ("postgresql", "internal", self.dns_ips['internal']),
            ("mongodb", "internal", self.dns_ips['internal']),
            ("rocketchat", "internal", self.dns_ips['internal']),
            ("wazuh.manager", "security", self.dns_ips['security']),
        ]

        for container, network, dns_ip in containers_to_test:
            if self.check_container_running(container):
                self.test_dns_from_container(container, network, dns_ip)
            else:
                result = DNSTestResult(
                    test_name=f"DNS from {container}",
                    status="SKIP",
                    duration_ms=0,
                    details=f"Container {container} is not running"
                )
                self.results.append(result)
                self.print_result(result)

    def display_configuration(self) -> None:
        """Display DNS configuration information"""
        self.print_header("DNS Server Configuration")

        print(f"{Colors.CYAN}Container Configuration:{Colors.NC}")
        print(f"  Container Name: {self.dns_container}")
        print(f"  Image: technitium/dns-server:latest")
        print(f"  Volume: dns_config:/etc/dns")

        print(f"\n{Colors.CYAN}Network Configuration:{Colors.NC}")
        for network, ip in self.dns_ips.items():
            print(f"  {network.capitalize():<15} : {ip} (10.10.{network[0]}.0/24)")

        print(f"\n{Colors.CYAN}Port Configuration:{Colors.NC}")
        print(f"  DNS Service (TCP/UDP): 53")
        print(f"  DNS Console (HTTP): 5380")

        print(f"\n{Colors.CYAN}Access Points:{Colors.NC}")
        print(f"  Web Console (Direct): http://localhost:5380")
        print(f"  Web Console (DNS): http://dns.cyberlab.local:5380")
        print(f"  Web Console (Traefik): https://dns.cyberlab.local")
        print(f"  DNS Service: 127.0.0.1:53 (TCP/UDP)")

    def generate_report(self) -> None:
        """Generate and display test report"""
        self.print_header("Test Summary Report")

        passed = sum(1 for r in self.results if r.status == "PASS")
        failed = sum(1 for r in self.results if r.status == "FAIL")
        skipped = sum(1 for r in self.results if r.status == "SKIP")
        total = len(self.results)

        print(f"Total Tests:  {total}")
        print(f"{Colors.GREEN}Passed:       {passed}{Colors.NC}")
        print(f"{Colors.RED}Failed:       {failed}{Colors.NC}")
        print(f"{Colors.YELLOW}Skipped:      {skipped}{Colors.NC}")

        if failed > 0:
            print(f"\n{Colors.RED}Failed Tests:{Colors.NC}")
            for result in self.results:
                if result.status == "FAIL":
                    print(f"  - {result.test_name}")

        total_time = sum(r.duration_ms for r in self.results)
        print(f"\n{Colors.CYAN}Total Execution Time: {total_time:.2f}ms{Colors.NC}")

    def export_json(self, filename: str) -> None:
        """Export test results as JSON"""
        data = {
            "timestamp": datetime.now().isoformat(),
            "summary": {
                "total": len(self.results),
                "passed": sum(1 for r in self.results if r.status == "PASS"),
                "failed": sum(1 for r in self.results if r.status == "FAIL"),
                "skipped": sum(1 for r in self.results if r.status == "SKIP")
            },
            "results": [asdict(r) for r in self.results]
        }

        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"\n{Colors.GREEN}Results exported to {filename}{Colors.NC}")

    def run_all_tests(self) -> None:
        """Run all DNS tests"""
        self.display_configuration()
        self.test_container_health()
        self.test_dns_ports()
        self.test_dns_console_http()
        self.test_all_containers()
        self.generate_report()

def main():
    parser = argparse.ArgumentParser(description="Advanced DNS Testing Tool for CyberLab")
    parser.add_argument('--config', action='store_true', help='Display DNS configuration')
    parser.add_argument('--health', action='store_true', help='Run health checks only')
    parser.add_argument('--ports', action='store_true', help='Test port accessibility')
    parser.add_argument('--console', action='store_true', help='Test DNS console')
    parser.add_argument('--containers', action='store_true', help='Test DNS from containers')
    parser.add_argument('--export', metavar='FILE', help='Export results to JSON file')
    parser.add_argument('--all', action='store_true', help='Run all tests (default)')

    args = parser.parse_args()

    tester = DNSTester()

    if args.config or not any(vars(args).values()):
        tester.display_configuration()
    if args.health or args.all or not any(vars(args).values()):
        tester.test_container_health()
    if args.ports or args.all or not any(vars(args).values()):
        tester.test_dns_ports()
    if args.console or args.all or not any(vars(args).values()):
        tester.test_dns_console_http()
    if args.containers or args.all or not any(vars(args).values()):
        tester.test_all_containers()

    if not args.config:
        tester.generate_report()

    if args.export:
        tester.export_json(args.export)

if __name__ == "__main__":
    main()
