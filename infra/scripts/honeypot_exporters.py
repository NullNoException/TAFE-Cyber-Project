#!/usr/bin/env python3
"""
Prometheus Exporters for Honeypot Services
Cowrie, Dionaea, Suricata, and TCPDump metrics export
"""

import json
import time
from pathlib import Path

from prometheus_client import Gauge, start_http_server


class CowrieExporter:
    """Export metrics from Cowrie SSH/Telnet honeypot logs"""

    def __init__(self, log_dir: str = "/var/log/cowrie"):
        self.log_dir = log_dir
        self.sessions = Gauge("cowrie_sessions", "Total Cowrie sessions")
        self.attacks = Gauge("cowrie_attacks", "Total attack attempts", ["protocol"])
        self.passwords_guessed = Gauge(
            "cowrie_passwords_guessed", "Total passwords guessed"
        )
        self.commands_executed = Gauge(
            "cowrie_commands", "Total commands executed", ["command"]
        )
        self.last_session_count = 0
        self.attack_counts = {}
        self.password_count = 0
        self.command_counts = {}

    def parse_logs(self):
        """Parse Cowrie JSON logs"""
        json_log = Path(self.log_dir) / "json" / "cowrie.json"
        if not json_log.exists():
            return

        try:
            session_count = 0
            attack_counts = {}
            password_count = 0
            command_counts = {}

            with open(json_log) as f:
                for line in f:
                    try:
                        entry = json.loads(line)

                        if entry.get("eventid") == "cowrie.session.connect":
                            session_count += 1
                            protocol = entry.get("protocol", "unknown")
                            attack_counts[protocol] = attack_counts.get(protocol, 0) + 1

                        elif entry.get("eventid") == "cowrie.command.input":
                            cmd = entry.get("input", "unknown")[:20]
                            command_counts[cmd] = command_counts.get(cmd, 0) + 1

                        elif entry.get("eventid") == "cowrie.log.closed":
                            if entry.get("credentials"):
                                password_count += 1

                    except json.JSONDecodeError:
                        continue

            # Update metrics
            if session_count != self.last_session_count:
                self.sessions.set(session_count)
                self.last_session_count = session_count

            for protocol, count in attack_counts.items():
                if protocol not in self.attack_counts or self.attack_counts[protocol] != count:
                    self.attacks.labels(protocol=protocol).set(count)
                    self.attack_counts[protocol] = count

            if password_count != self.password_count:
                self.passwords_guessed.set(password_count)
                self.password_count = password_count

            for cmd, count in command_counts.items():
                if cmd not in self.command_counts or self.command_counts[cmd] != count:
                    self.commands_executed.labels(command=cmd).set(count)
                    self.command_counts[cmd] = count

        except IOError as e:
            print(f"Error reading Cowrie logs: {e}")


class DioneaeExporter:
    """Export metrics from Dionaea honeypot"""

    def __init__(self, log_dir: str = "/opt/dionaea/var"):
        self.log_dir = log_dir
        self.offers = Gauge("dionaea_offers", "Dionaea offers sent", ["service"])
        self.last_offers = {}

    def parse_logs(self):
        """Parse Dionaea logs"""
        log_dir = Path(self.log_dir) / "log"
        if not log_dir.exists():
            return

        try:
            # Parse connection logs
            bistream_log = log_dir / "dionaea-bistream.log"
            if bistream_log.exists():
                offer_counts = {}
                with open(bistream_log) as f:
                    for line in f:
                        if "offer_set" in line:
                            service = self._extract_service(line)
                            offer_counts[service] = offer_counts.get(service, 0) + 1

                # Update metrics only if changed
                for service, count in offer_counts.items():
                    if service not in self.last_offers or self.last_offers[service] != count:
                        self.offers.labels(service=service).set(count)
                        self.last_offers[service] = count

        except IOError as e:
            print(f"Error reading Dionaea logs: {e}")

    @staticmethod
    def _extract_service(line: str) -> str:
        """Extract service name from log line"""
        services = ["ftp", "http", "smb", "mssql", "mysql", "rdp"]
        for service in services:
            if service in line.lower():
                return service
        return "unknown"


class SuricataExporter:
    """Export metrics from Suricata IDS/IPS"""

    def __init__(self, log_dir: str = "/var/log/suricata"):
        self.log_dir = log_dir
        self.alerts = Gauge(
            "suricata_alerts", "Total Suricata alerts", ["alert_severity", "rule_id"]
        )
        self.packets = Gauge("suricata_packets", "Total packets processed")
        self.drops = Gauge("suricata_drops", "Dropped packets", ["reason"])
        self.last_packet_count = 0
        self.alert_counts = {}

    def parse_logs(self):
        """Parse Suricata eve.json logs"""
        eve_log = Path(self.log_dir) / "eve.json"
        if not eve_log.exists():
            return

        try:
            drop_stats_dict = {}
            alert_counts = {}

            with open(eve_log) as f:
                for line in f:
                    try:
                        entry = json.loads(line)

                        if entry.get("event_type") == "alert":
                            severity = entry.get("alert", {}).get("severity", "unknown")
                            rule_id = entry.get("alert", {}).get("rule_id", "unknown")
                            key = f"{severity}:{rule_id}"
                            alert_counts[key] = alert_counts.get(key, 0) + 1

                        elif entry.get("event_type") == "stats":
                            stats = entry.get("stats", {})
                            total_packets = stats.get("decoder", {}).get("pkts", 0)

                            # Update packet count if changed
                            if total_packets != self.last_packet_count:
                                self.packets.set(total_packets)
                                self.last_packet_count = total_packets

                            drop_stats = stats.get("capture", {})
                            for reason, count in drop_stats.items():
                                drop_stats_dict[reason] = count

                    except json.JSONDecodeError:
                        continue

            # Update alert statistics
            for key, count in alert_counts.items():
                severity, rule_id = key.split(":", 1)
                if key not in self.alert_counts or self.alert_counts[key] != count:
                    self.alerts.labels(alert_severity=severity, rule_id=rule_id).set(count)
                    self.alert_counts[key] = count

            # Update drop statistics
            for reason, count in drop_stats_dict.items():
                self.drops.labels(reason=reason).set(count)

        except IOError as e:
            print(f"Error reading Suricata logs: {e}")


class TCPDumpExporter:
    """Export metrics from TCPDump packet captures"""

    def __init__(self, pcap_dir: str = "/data/pcap"):
        self.pcap_dir = pcap_dir
        self.pcap_files = Gauge("tcpdump_pcap_files", "Total PCAP files")
        self.pcap_size = Gauge("tcpdump_pcap_size_bytes", "Total PCAP size", ["file"])
        self.last_file_count = 0

    def parse_pcaps(self):
        """Parse PCAP file statistics"""
        pcap_dir = Path(self.pcap_dir)
        if not pcap_dir.exists():
            return

        try:
            pcap_files = list(pcap_dir.glob("*.pcap*"))
            file_count = len(pcap_files)

            # Update file count if changed
            if file_count != self.last_file_count:
                self.pcap_files.set(file_count)
                self.last_file_count = file_count

            for pcap_file in pcap_files:
                size = pcap_file.stat().st_size
                self.pcap_size.labels(file=pcap_file.name).set(size)

        except IOError as e:
            print(f"Error reading PCAP files: {e}")


def main():
    """Main exporter server"""
    # Start Prometheus HTTP server
    start_http_server(9191)  # Port for honeypot exporters

    # Initialize exporters
    cowrie = CowrieExporter()
    dionaea = DioneaeExporter()
    suricata = SuricataExporter()
    tcpdump = TCPDumpExporter()

    print("Starting Honeypot Exporters on port 9191")

    # Continuously update metrics
    while True:
        try:
            cowrie.parse_logs()
            dionaea.parse_logs()
            suricata.parse_logs()
            tcpdump.parse_pcaps()
            time.sleep(30)  # Update metrics every 30 seconds
        except Exception as e:
            print(f"Error updating metrics: {e}")
            time.sleep(60)


if __name__ == "__main__":
    main()
