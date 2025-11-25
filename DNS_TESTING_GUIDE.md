# DNS Server Testing Guide - CyberLab Infrastructure

## Overview

This guide provides comprehensive methods to test and verify DNS functionality across all network segments of the CyberLab infrastructure. The DNS server (Technitium) is deployed as a central service accessible from all networks.

## Quick Start

### Automated Testing

#### Option 1: Bash Script (Simple)
```bash
cd infra
chmod +x scripts/test-dns.sh
./scripts/test-dns.sh all          # Run all tests
./scripts/test-dns.sh quick        # Quick summary
./scripts/test-dns.sh dns-console  # Test console only
```

#### Option 2: Python Script (Advanced)
```bash
cd infra
chmod +x scripts/test-dns-advanced.py
python3 scripts/test-dns-advanced.py          # Run all tests
python3 scripts/test-dns-advanced.py --config # Show configuration
python3 scripts/test-dns-advanced.py --export results.json # Export results
```

---

## DNS Server Configuration

### Network Connectivity

The DNS server is deployed across all 5 networks for maximum accessibility:

| Network | IP Address | CIDR | Gateway |
|---------|-----------|------|---------|
| External (VPN) | 10.10.0.50 | 10.10.0.0/24 | 10.10.0.1 |
| DMZ (Public) | 10.10.10.50 | 10.10.10.0/24 | 10.10.10.1 |
| Internal (Protected) | 10.10.20.50 | 10.10.20.0/24 | 10.10.20.1 |
| Security (Monitoring) | 10.10.30.50 | 10.10.30.0/24 | 10.10.30.1 |
| Management (Admin) | 10.10.40.50 | 10.10.40.0/24 | 10.10.40.1 |

### Ports

- **DNS Service**: Port 53 (TCP and UDP)
- **DNS Web Console**: Port 5380 (HTTP)

### Access Points

```
Direct Access:
  http://localhost:5380

Domain Names:
  http://dns.cyberlab.local:5380
  http://dns-console.cyberlab.local:5380

Via Traefik (Secure):
  https://dns.cyberlab.local (with TLS)
```

---

## Manual Testing Methods

### 1. Testing DNS Console Web Interface

#### Via Browser (Host Machine)
```
http://localhost:5380
```

#### Via curl
```bash
# Check if console is responding
curl -v http://localhost:5380

# Check HTTP status
curl -o /dev/null -w "%{http_code}\n" http://localhost:5380

# Check response headers
curl -I http://localhost:5380
```

#### Via Docker
```bash
# From any container with curl installed
docker exec traefik curl -v http://dns-server:5380
```

---

### 2. Testing DNS Resolution from External Network

#### From Host Machine Using `dig`
```bash
# Query DNS server directly
dig @127.0.0.1 dns-server

# Query specific domain
dig @127.0.0.1 cyberlab.local

# Query with short output
dig @127.0.0.1 dns-server +short

# Query with full output
dig @127.0.0.1 dns-server +noall +answer
```

#### From Host Machine Using `nslookup`
```bash
# Basic DNS query
nslookup dns-server 127.0.0.1

# Interactive mode
nslookup
> server 127.0.0.1
> dns-server
> exit
```

#### DNS Port Connectivity Test
```bash
# Test TCP port 53
nc -zv 127.0.0.1 53

# Test UDP port 53
echo "test" | nc -u 127.0.0.1 53

# Using Bash builtin (TCP only)
timeout 2 bash -c "</dev/tcp/127.0.0.1/53" && echo "Port 53 is open"
```

---

### 3. Testing DNS from Internal Network (Containers)

#### From DMZ/Internal Containers
```bash
# Test from nginx container
docker exec nginx nslookup dns-server 10.10.20.50
docker exec nginx dig @10.10.20.50 dns-server +short

# Test from PostgreSQL container
docker exec postgresql nslookup dns-server 10.10.20.50

# Test from MongoDB container
docker exec mongodb nslookup dns-server 10.10.20.50

# Test from OpenLDAP container
docker exec openldap nslookup dns-server 10.10.20.50
```

#### From Security Network Containers
```bash
# Test from Wazuh Manager
docker exec wazuh.manager nslookup dns-server 10.10.30.50

# Test from Wazuh Indexer
docker exec wazuh.indexer nslookup dns-server 10.10.30.50

# Test from Suricata
docker exec suricata nslookup dns-server 10.10.30.50
```

#### From Management Network Containers
```bash
# Test from Traefik
docker exec traefik nslookup dns-server 10.10.40.50

# Test from OpenVPN
docker exec openvpn nslookup dns-server 10.10.40.60
```

---

### 4. Testing DNS Resolution for Services

#### Test Internal Service Resolution
```bash
# From any container, test resolving other services
docker exec nginx nslookup postgresql 10.10.20.50
docker exec nginx nslookup openldap 10.10.20.50
docker exec nginx nslookup rocketchat 10.10.20.50
docker exec nginx nslookup mongodb 10.10.20.50

# Test custom domains
docker exec nginx nslookup cyberlab.local 10.10.20.50
docker exec nginx nslookup web.cyberlab.local 10.10.20.50
docker exec nginx nslookup chat.cyberlab.local 10.10.20.50
docker exec nginx nslookup wazuh.cyberlab.local 10.10.20.50
```

#### Test Recursive Resolution (External Domains)
```bash
# From container, test external domain resolution (if enabled)
docker exec nginx dig @10.10.20.50 google.com +short

# Check if recursion is allowed
docker exec nginx dig @10.10.20.50 +recurse google.com
```

---

### 5. Detailed Diagnostic Commands

#### Docker Container DNS Configuration
```bash
# Check DNS configuration inside a container
docker exec nginx cat /etc/resolv.conf

# Test nameserver entries
docker exec nginx nslookup google.com

# Check container network settings
docker inspect dns-server --format='{{json .NetworkSettings.Networks}}' | python3 -m json.tool
```

#### DNS Service Logs
```bash
# View DNS container logs
docker logs dns-server

# Watch DNS logs in real-time
docker logs -f dns-server

# View last 100 lines
docker logs dns-server --tail=100

# Filter for errors
docker logs dns-server | grep -i "error\|fail\|warning"
```

#### DNS Container Status
```bash
# Get detailed container information
docker inspect dns-server

# Check container resource usage
docker stats dns-server

# Check if container is healthy (if health check is configured)
docker inspect dns-server --format='{{.State.Health.Status}}'
```

---

### 6. Network Connectivity Testing

#### Test DNS Port Accessibility
```bash
# From host
sudo tcpdump -i any "port 53"  # Monitor DNS traffic

# From container
docker exec traefik tcpdump -i any "port 53"
```

#### Trace DNS Queries
```bash
# Using dig with trace
dig @127.0.0.1 +trace google.com

# Using nslookup with debug
nslookup -debug dns-server 127.0.0.1
```

#### DNS Query Performance Testing
```bash
# Measure DNS query time
time dig @127.0.0.1 dns-server

# Batch query multiple domains
for domain in dns-server nginx postgresql openldap rocketchat; do
  echo "=== $domain ==="
  dig @127.0.0.1 $domain +short
done

# Load testing (benchmark)
# Using ab (Apache Bench) for HTTP console
ab -n 100 -c 10 http://localhost:5380/
```

---

## Test Scenarios

### Scenario 1: Verify DNS is Working from All Networks

```bash
#!/bin/bash

# Test from each network
echo "=== Testing from External Network (OpenVPN) ==="
docker exec openvpn nslookup dns-server 10.10.0.50

echo "=== Testing from DMZ Network (Traefik) ==="
docker exec traefik nslookup dns-server 10.10.10.50

echo "=== Testing from Internal Network (Nginx) ==="
docker exec nginx nslookup dns-server 10.10.20.50

echo "=== Testing from Security Network (Wazuh) ==="
docker exec wazuh.manager nslookup dns-server 10.10.30.50

echo "=== Testing from Management Network (Traefik) ==="
docker exec traefik nslookup dns-server 10.10.40.50
```

### Scenario 2: Verify Service Discovery

```bash
#!/bin/bash

# Test if containers can resolve each other
services=("nginx" "postgresql" "openldap" "mongodb" "rocketchat" "wazuh.manager")

docker exec nginx sh -c '
  for service in '"$(printf '%s ' "${services[@]}")"'; do
    echo "Resolving $service..."
    nslookup "$service" 10.10.20.50
  done
'
```

### Scenario 3: Verify DNS Console Accessibility

```bash
#!/bin/bash

# Test HTTP access
echo "Testing DNS Console HTTP..."
curl -v http://localhost:5380/

# Test via Traefik
echo "Testing via Traefik..."
curl -v https://dns.cyberlab.local/ -k

# Test from container
echo "Testing from container..."
docker exec traefik curl http://dns-server:5380/
```

### Scenario 4: Verify Recursion Policy

```bash
#!/bin/bash

# Test that private networks can use recursion
docker exec nginx dig @10.10.20.50 +recurse google.com

# Verify public queries are blocked (if configured)
# This should fail from outside
dig @127.0.0.1 google.com  # May be blocked depending on configuration
```

---

## Troubleshooting

### Issue: DNS Container Not Running

**Symptoms**: Container not found or not responding
```bash
# Check if container exists
docker ps -a | grep dns-server

# Check container logs for startup errors
docker logs dns-server

# Restart container
docker restart dns-server

# Check container health
docker inspect dns-server --format='{{.State}}'
```

### Issue: DNS Port 53 Not Accessible

**Symptoms**: Cannot connect to DNS port
```bash
# Check port binding
docker port dns-server

# Check if port is in use on host
lsof -i :53

# Verify with netstat
netstat -tlnp | grep 53

# Check firewall rules
sudo iptables -L | grep 53
```

### Issue: DNS Resolution Failing from Containers

**Symptoms**: nslookup/dig returning NXDOMAIN or timeouts
```bash
# Verify container can reach DNS server IP
docker exec nginx ping -c 1 10.10.20.50

# Check network connectivity
docker exec nginx traceroute 10.10.20.50

# Verify DNS server is listening
docker logs dns-server | tail -50

# Check if container has DNS configuration
docker exec nginx cat /etc/resolv.conf
```

### Issue: DNS Console Web UI Not Accessible

**Symptoms**: Cannot access http://localhost:5380
```bash
# Check if port 5380 is listening
lsof -i :5380

# Test local connectivity
curl http://localhost:5380

# Check container network
docker exec dns-server netstat -tlnp | grep 5380

# Check Traefik logs if using HTTPS access
docker logs traefik | grep dns
```

---

## Advanced Testing

### Performance Testing
```bash
# DNS query latency
dig @127.0.0.1 dns-server | grep "Query time"

# Batch query multiple times
for i in {1..10}; do
  dig @127.0.0.1 dns-server +stats
done

# Load testing with dnsbench (if available)
dnsbench -s 127.0.0.1 -q 100
```

### Security Testing
```bash
# Test DNS security headers
curl -I http://localhost:5380

# Test DNSSEC (if enabled)
dig @127.0.0.1 google.com +dnssec

# Test rate limiting
for i in {1..100}; do dig @127.0.0.1 dns-server & done
```

### Network Analysis
```bash
# Monitor DNS traffic in real-time
docker exec dns-server tcpdump -i eth0 "port 53"

# Packet capture for analysis
docker exec dns-server tcpdump -i eth0 -w dns.pcap "port 53"

# View pcap file
tcpdump -r dns.pcap
```

---

## Expected Results

### Successful DNS Resolution
```
NAME: dns-server
ADDRESS: 10.10.x.50
```

### Successful Port Connection
```
✓ Port 53/TCP is accessible
✓ Port 53/UDP is accessible
✓ Port 5380/TCP is accessible
```

### Successful Console Access
```
HTTP/1.1 200 OK
(or 301/302 redirect)
```

---

## Monitoring Continuous

### Watch DNS Activity
```bash
# Real-time DNS logs
docker logs -f dns-server
```

### Health Check Script
```bash
#!/bin/bash
while true; do
  if docker exec nginx nslookup dns-server 10.10.20.50 > /dev/null 2>&1; then
    echo "[$(date)] DNS is healthy"
  else
    echo "[$(date)] DNS check failed - alerting..."
  fi
  sleep 30
done
```

---

## Documentation Files

- **Bash Testing Script**: `infra/scripts/test-dns.sh`
- **Python Testing Tool**: `infra/scripts/test-dns-advanced.py`
- **Docker Compose Config**: `infra/docker-compose.yml` (DNS service section)
- **Traefik Configuration**: `infra/configs/traefik/dynamic.yml`

---

## Quick Reference Commands

```bash
# Quick test from host
dig @127.0.0.1 dns-server

# Quick test from container
docker exec nginx nslookup dns-server 10.10.20.50

# View logs
docker logs -f dns-server

# Access web console
# http://localhost:5380

# Run automated tests
./infra/scripts/test-dns.sh all

# Export results
python3 infra/scripts/test-dns-advanced.py --export results.json
```

---

## Next Steps

1. Run the automated testing scripts
2. Verify DNS is accessible from all network segments
3. Configure internal DNS records if needed
4. Set up monitoring and alerting for DNS health
5. Document any custom DNS configurations

---

**Last Updated**: November 2024
**Version**: 1.0
