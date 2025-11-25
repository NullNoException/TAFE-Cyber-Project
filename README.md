# CyberLab: Enterprise Security Infrastructure

A comprehensive, production-grade cybersecurity lab environment for defensive security training, SIEM deployment, threat detection, and incident response. This infrastructure implements defense-in-depth with 5 isolated network segments, 15 integrated security services, and 300+ detection rules.

**Status:** ✅ **Fully Operational** (Deployed: November 24, 2025)
**Platform:** macOS/Linux with Docker
**Total Services:** 15 containers | **Network Segments:** 5 | **Detection Rules:** 300+

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Services & Components](#services--components)
4. [Quick Start](#quick-start)
5. [Prerequisites](#prerequisites)
6. [Installation & Setup](#installation--setup)
7. [Running Scripts](#running-scripts)
8. [Accessing Services](#accessing-services)
9. [Configuration](#configuration)
10. [Security Policies](#security-policies)
11. [Troubleshooting](#troubleshooting)
12. [Documentation](#documentation)

---

## Project Overview

**CyberLab** is an integrated cybersecurity infrastructure designed for:

- **Security Training:** Complete lab for cybersecurity students and professionals
- **SIEM Deployment:** Test and learn Wazuh configuration, log analysis
- **Threat Detection:** IDS/IPS rule development with Suricata (300+ rules)
- **Container Security:** Practice NeuVector policies and threat detection
- **Access Control:** Test network segmentation with 5-layer defense
- **Incident Response:** Simulated breach scenarios with centralized logging
- **Directory Services:** LDAP administration and authentication
- **Backup & Recovery:** Disaster recovery procedures with 30-day retention

### Key Features

✅ **Centralized SIEM** - Wazuh for log aggregation, correlation, and threat analysis
✅ **Network IDS/IPS** - Suricata with 300+ rules covering reconnaissance, SQL injection, RCE, malware, DDoS, and zero-day attacks
✅ **Container Security** - NeuVector for runtime threat detection and vulnerability scanning
✅ **VPN Access** - OpenVPN with secure remote access and admin panel
✅ **Authentication** - OpenLDAP for identity management across all services
✅ **Reverse Proxy** - Traefik with access control policies and TLS termination
✅ **Backup System** - Automated daily backups with 30-day retention
✅ **Infrastructure-as-Code** - Docker Compose for reproducibility and versioning

---

## Architecture

### Network Design (5-Layer Defense-In-Depth)

```
┌──────────────────────────────────────────────────────────┐
│                    macOS Host Network                    │
│                      127.0.0.1:xxxx                      │
└──────────────────────────────────┬──────────────────────┘
                                   │
    ┌──────────────────────────────┼──────────────────────┐
    │                              │                      │
[LAYER 1]                    [LAYER 2]            [LAYERS 3-5]
External/VPN               DMZ/Public           Protected Services
10.10.0.0/24              10.10.10.0/24         10.10.20.0/24
                                                10.10.30.0/24
    │                          │                 10.10.40.0/24
    │                          │                      │
OpenVPN:10.10.0.20      Traefik:10.10.10.5    LDAP, PostgreSQL
NeuVector:10.10.0.10    Nginx:10.10.10.10     Wazuh, Monitoring
Traefik:10.10.0.30      DNS:10.10.10.50       Workstation, Backup
                        Suricata:10.10.10.70
                        Wazuh Mgr:10.10.10.60
```

### Network Segments

| Layer | Network | Purpose | Services |
|-------|---------|---------|----------|
| **Layer 1** | 10.10.0.0/24 | **External/VPN** - Remote access entry point | OpenVPN, NeuVector, Traefik |
| **Layer 2** | 10.10.10.0/24 | **DMZ** - Public-facing services | Traefik, Nginx, DNS, Suricata, Wazuh Mgr |
| **Layer 3** | 10.10.20.0/24 | **Internal** - Protected services & data | PostgreSQL, MongoDB, LDAP, Rocket.Chat, Workstation |
| **Layer 4** | 10.10.30.0/24 | **Security** - Isolated monitoring & analysis | Wazuh (Indexer, Dashboard), Suricata, NeuVector |
| **Layer 5** | 10.10.40.0/24 | **Management** - Admin interfaces | Traefik Dashboard, OpenVPN Admin, DNS Console |

---

## Services & Components

| Service | Container | Version | Ports | Role | Networks |
|---------|-----------|---------|-------|------|----------|
| **Wazuh Manager** | wazuh/wazuh-manager | 4.14.1 | 514/UDP, 1514-1515 | SIEM central manager | Security, DMZ, Internal, Mgmt |
| **Wazuh Indexer** | wazuh/wazuh-indexer | 4.14.1 | 9200 | OpenSearch log indexing | Security, Mgmt |
| **Wazuh Dashboard** | wazuh/wazuh-dashboard | 4.14.1 | 5601 | SIEM web UI & analytics | Security, Mgmt |
| **Suricata** | jasonish/suricata | latest | Host network | Network IDS/IPS | DMZ, Security |
| **NeuVector** | neuvector.allinone | 5.3.5 | 8443, 18300-18401 | Container security | External, DMZ, Internal, Security, Mgmt |
| **Traefik** | traefik | v3.0 | 80, 443, 8082 | Reverse proxy & load balancer | All networks |
| **Nginx** | nginx | alpine | 80 | Web server | DMZ, Internal |
| **OpenVPN** | openvpn/openvpn-as | latest | 943, 1194/UDP | VPN gateway | External, Mgmt |
| **OpenLDAP** | osixia/openldap | latest | 389, 636 | Directory service | Internal, Security, Mgmt |
| **phpLDAPadmin** | osixia/phpldapadmin | latest | 80 | LDAP web UI | Internal, Security |
| **PostgreSQL** | postgres | 15-alpine | 5432 | Database server | Internal |
| **MongoDB** | mongo | 5 | 27017 | Document database | Internal |
| **Rocket.Chat** | rocketchat | latest | 80/443 | Team communication | Internal, Security |
| **Technitium DNS** | technitium/dns-server | latest | 53, 5380 | DNS server & console | All networks |
| **Workstation** | dorowu/ubuntu-desktop-lxde-vnc | latest | 5900, 6080 | GUI desktop (VNC) | Internal |
| **Backup Service** | alpine | latest | — | Automated backups | Internal, Security, Mgmt |

**Total: 15 Active Containers**

---

## Quick Start

### Start All Services

```bash
cd infra
docker-compose up -d
```

### Check Service Status

```bash
docker-compose ps
```

You should see all 15 services as `running`.

### View Logs

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f wazuh.manager
docker-compose logs -f suricata
docker-compose logs -f traefik
```

### Stop All Services

```bash
docker-compose down
```

---

## Prerequisites

### System Requirements

- **Docker Engine** (v20.10+)
- **Docker Compose** (v2.0+)
- **macOS/Linux** (Windows with WSL2 supported)
- **Memory:** 8GB minimum (16GB+ recommended)
- **Storage:** 50GB+ available space for volumes and logs
- **Network:** Static or reserved IP if accessing remotely

### Software

Ensure you have installed:

```bash
# macOS (using Homebrew)
brew install docker docker-compose

# Linux (Ubuntu/Debian)
sudo apt-get install docker.io docker-compose

# Verify installation
docker --version
docker-compose --version
```

### Network Configuration

Add DNS entries to your `/etc/hosts` (or `C:\Windows\System32\drivers\etc\hosts` on Windows):

```
127.0.0.1       localhost
127.0.0.1       cyberlab.local
127.0.0.1       traefik.cyberlab.local
127.0.0.1       wazuh.cyberlab.local
127.0.0.1       neuvector.cyberlab.local
127.0.0.1       vpn.cyberlab.local
127.0.0.1       ldap.cyberlab.local
127.0.0.1       dns.cyberlab.local
127.0.0.1       rocketchat.cyberlab.local
```

Or use the provided hosts file entries in `HOSTS_FILE_ENTRIES.txt`.

---

## Installation & Setup

### Step 1: Clone or Extract Project

```bash
cd /path/to/CyberSecurity-Diploma/Project
```

### Step 2: Configure Environment Variables

```bash
# Copy template to create .env file
cp infra/.env.template infra/.env

# Edit .env with your desired values
nano infra/.env
```

Key variables to set:

```env
# Service Passwords (CHANGE THESE)
LDAP_ADMIN_PASSWORD=admin
POSTGRES_PASSWORD=SecureP@ssw0rd
MONGODB_PASSWORD=your_secure_password
OPENVPN_ADMIN_PASSWORD=your_admin_password

# Network Configuration
EXTERNAL_NETWORK=10.10.0.0/24
DMZ_NETWORK=10.10.10.0/24
INTERNAL_NETWORK=10.10.20.0/24
SECURITY_NETWORK=10.10.30.0/24
MGMT_NETWORK=10.10.40.0/24

# Service Hostnames
DOMAIN=cyberlab.local
```

### Step 3: Generate Passwords (Optional)

```bash
cd infra/scripts
chmod +x generate-passwords.sh
./generate-passwords.sh
```

This generates secure passwords and saves them to `infra/secrets/`.

### Step 4: Start Infrastructure

```bash
cd infra
docker-compose up -d
```

Wait 60-90 seconds for all services to fully initialize.

### Step 5: Initialize Services

#### Seed LDAP Directory

```bash
cd infra/scripts
chmod +x seed-ldap.sh
./seed-ldap.sh
```

This populates OpenLDAP with initial users and groups:
- `admin` (cn=admin,dc=cyberlab,dc=local)
- `security_team` group
- Test users for access control testing

#### Initialize DNS Server

```bash
cd infra/scripts
chmod +x init-dns-tools.sh
./init-dns-tools.sh
```

#### Initialize OpenVPN (Optional)

```bash
cd infra/scripts
chmod +x init-openvpn.sh
./init-openvpn.sh
```

This configures the OpenVPN Access Server with admin credentials and generates client profiles.

### Step 6: Verify Deployment

```bash
cd infra/scripts
chmod +x verify-network-access.sh
./verify-network-access.sh
```

This tests connectivity between services and validates access control policies.

---

## Running Scripts

### DNS Testing

**Basic DNS Testing Across All Networks:**

```bash
cd infra/scripts
chmod +x test-dns.sh
./test-dns.sh all
```

Test specific network:
```bash
./test-dns.sh external    # Layer 1
./test-dns.sh internal    # Layer 3
./test-dns.sh security    # Layer 4
./test-dns.sh management  # Layer 5
./test-dns.sh dns-console # DNS web UI
```

**Advanced DNS Testing with Diagnostics:**

```bash
cd infra/scripts
chmod +x test-dns-advanced.py
python3 test-dns-advanced.py
```

Export results to JSON:
```bash
python3 test-dns-advanced.py --export dns-results.json
```

View configuration:
```bash
python3 test-dns-advanced.py --config
```

### Network Verification

```bash
cd infra/scripts
chmod +x verify-network-access.sh
./verify-network-access.sh
```

This validates:
- Service-to-service connectivity
- Access control policies
- Network routing
- Identifies connectivity issues

### Backup Operations

**Automatic Backup:**
- Runs daily at 02:00 UTC
- 30-day retention policy
- All volumes backed up

**Manual Backup:**

```bash
# Create manual backup
docker exec backup tar -czf "/backups/manual-$(date +%Y%m%d_%H%M%S).tar.gz" /backup/

# List backups
docker exec backup ls -lh /backups/

# Restore from backup
docker exec backup tar -xzf "/backups/manual-YYYYMMDD_HHMMSS.tar.gz" -C /backup/
```

### Database Operations

**PostgreSQL:**

```bash
# Connect to PostgreSQL
docker exec postgresql psql -U postgres -c "SELECT version();"

# List databases
docker exec postgresql psql -U postgres -c "\l"

# Create database
docker exec postgresql psql -U postgres -c "CREATE DATABASE myapp;"
```

**MongoDB:**

```bash
# Connect to MongoDB
docker exec mongodb mongosh -u root -p $MONGODB_PASSWORD

# List databases
docker exec mongodb mongosh -u root -p $MONGODB_PASSWORD --eval "db.adminCommand('listDatabases')"
```

### LDAP Operations

**Search LDAP Directory:**

```bash
# Search all users
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x

# Search specific user
docker exec openldap ldapsearch -b "cn=admin,dc=cyberlab,dc=local" -x

# List all users
docker exec openldap ldapsearch -b "ou=users,dc=cyberlab,dc=local" -x
```

**Modify LDAP:**

```bash
# Change admin password
docker exec openldap ldappasswd -D "cn=admin,dc=cyberlab,dc=local" -W -S "uid=newuser,ou=users,dc=cyberlab,dc=local"
```

---

## Accessing Services

### Web Interface URLs

Access these services in your browser (requires `/etc/hosts` configuration):

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **Traefik Dashboard** | https://traefik.cyberlab.local | — | — |
| **Wazuh Dashboard** | https://wazuh.cyberlab.local | kibanaserver | kibanaserver |
| **NeuVector** | https://neuvector.cyberlab.local | admin | admin |
| **OpenVPN Admin** | https://vpn.cyberlab.local | openvpn | (from secrets) |
| **LDAP Admin** | https://ldap.cyberlab.local | cn=admin,dc=cyberlab,dc=local | admin |
| **DNS Console** | http://dns.cyberlab.local:5380 | admin | admin |
| **Rocket.Chat** | https://rocketchat.cyberlab.local | (first login) | (first login) |
| **Workstation VNC** | http://localhost:6080 | — | — |

### Command-Line Access

**Execute commands in containers:**

```bash
# General syntax
docker exec <container_name> <command>

# Examples:
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x
docker exec postgresql psql -U postgres -c "\l"
docker exec traefik traefik version
```

**Interactive shell:**

```bash
docker exec -it <container_name> /bin/bash
# or
docker exec -it <container_name> /bin/sh
```

### Port Mappings (Host Access)

Some services expose ports directly to the host:

| Service | Port | Purpose |
|---------|------|---------|
| Traefik | 80, 443 | HTTP/HTTPS (all services) |
| Traefik Dashboard | 8082 | Infrastructure management |
| Suricata | Host network | Network capture & IDS |
| NeuVector | 8443 | Container security UI |
| OpenVPN | 943, 1194/UDP | VPN server |
| Workstation VNC | 5900, 6080 | Remote desktop |

---

## Configuration

### Key Configuration Files

```
infra/
├── docker-compose.yml         # Complete service definitions
├── .env                        # Environment variables (create from .env.template)
│
├── configs/
│   ├── traefik/
│   │   ├── traefik.yml         # Traefik main config
│   │   └── dynamic.yml         # Service routing & access policies
│   │
│   ├── wazuh/
│   │   ├── wazuh_manager.conf  # Wazuh SIEM configuration
│   │   ├── opensearch_dashboards.yml
│   │   └── *_ssl_certs/        # SSL certificates
│   │
│   ├── suricata/
│   │   ├── suricata.yaml       # IDS/IPS configuration
│   │   └── suricata-rules.rules # 300+ detection rules
│   │
│   ├── nginx/
│   │   └── nginx.conf          # Web server configuration
│   │
│   └── ldap/
│       └── ldif/               # LDAP schema definitions
│
├── scripts/
│   ├── test-dns.sh
│   ├── test-dns-advanced.py
│   ├── seed-ldap.sh
│   ├── init-openvpn.sh
│   ├── init-dns-tools.sh
│   ├── generate-passwords.sh
│   └── verify-network-access.sh
│
└── volumes/                    # Persistent data (auto-created)
    ├── wazuh_*
    ├── ldap_*
    ├── postgres_*
    ├── mongodb_*
    └── ...
```

### Modifying Configuration

**To change service parameters:**

1. Edit `infra/.env`:
   ```bash
   nano infra/.env
   ```

2. Edit relevant config file in `infra/configs/`:
   ```bash
   nano infra/configs/traefik/dynamic.yml
   ```

3. Restart affected services:
   ```bash
   docker-compose restart <service_name>
   ```

4. Verify changes:
   ```bash
   docker logs -f <service_name>
   ```

### Enabling/Disabling Services

To disable a service, comment it out in `docker-compose.yml`:

```yaml
# openvpn:
#   image: openvpn/openvpn-as:latest
#   ...
```

Then restart:
```bash
docker-compose up -d
```

---

## Security Policies

### Network Access Control

Traefik enforces strict IP-based whitelisting for all services using 5 access policies:

#### 1. Admin-Only Access
- **Allowed Networks:** Management (10.10.40.0/24) + Security (10.10.30.0/24)
- **Services:** Traefik Dashboard, OpenVPN Admin, DNS Console

#### 2. Security Network Access
- **Allowed Networks:** Security (10.10.30.0/24) + Management (10.10.40.0/24)
- **Services:** Wazuh Dashboard, Wazuh API, NeuVector Console, Suricata Manager

#### 3. Internal Network Access
- **Allowed Networks:** Internal (10.10.20.0/24) + Security (10.10.30.0/24) + Management (10.10.40.0/24)
- **Services:** LDAP, phpLDAPadmin, Rocket.Chat, Workstation

#### 4. Public Services Access
- **Allowed Networks:** All networks (10.10.0.0/24 - 10.10.40.0/24)
- **Services:** Nginx Web Server, Public APIs

#### 5. Localhost Only
- **Allowed Networks:** 127.0.0.1/32 (Docker internal)
- **Services:** Internal monitoring endpoints

### Changing Default Credentials

⚠️ **IMPORTANT: Change default credentials immediately in production!**

```bash
# Edit .env file
nano infra/.env

# Change these variables:
LDAP_ADMIN_PASSWORD=MyNewSecurePassword123
POSTGRES_PASSWORD=MyPostgresPassword123
MONGODB_PASSWORD=MyMongoPassword123
OPENVPN_ADMIN_PASSWORD=MyVPNPassword123

# Restart services
docker-compose down
docker-compose up -d
```

### SSL/TLS Certificates

The infrastructure includes self-signed certificates for development. For production:

1. **Generate proper certificates:**
   ```bash
   # Using Let's Encrypt (if publicly accessible)
   certbot certonly --standalone -d cyberlab.local
   ```

2. **Update Traefik configuration:**
   ```bash
   nano infra/configs/traefik/traefik.yml
   ```

3. **Copy certificates to:**
   ```bash
   infra/certs/
   ```

---

## Troubleshooting

### Service Won't Start

**Check logs:**
```bash
docker-compose logs <service_name>
```

**Common issues:**

1. **Port already in use:**
   ```bash
   # Find what's using port
   lsof -i :80
   lsof -i :443

   # Kill process
   kill -9 <PID>
   ```

2. **Insufficient memory:**
   ```bash
   # Check Docker resources
   docker stats

   # Increase Docker memory limit
   # macOS: Docker Desktop > Preferences > Resources
   ```

3. **Volume mount errors:**
   ```bash
   # Check volumes
   docker volume ls

   # Inspect volume
   docker volume inspect <volume_name>
   ```

### Network Connectivity Issues

**Test DNS resolution:**
```bash
docker exec nginx nslookup wazuh.cyberlab.local
docker exec nginx nslookup google.com
```

**Test network connectivity:**
```bash
cd infra/scripts
./verify-network-access.sh
```

### Service Health Checks

**Check if service is healthy:**
```bash
docker-compose ps
```

Look for `(healthy)` or `(unhealthy)` status.

**Restart unhealthy service:**
```bash
docker-compose restart <service_name>
docker-compose logs -f <service_name>
```

### LDAP Connection Issues

```bash
# Test LDAP connectivity
docker exec nginx ldapsearch -h openldap -p 389 -x -b "dc=cyberlab,dc=local"

# Check LDAP status
docker exec openldap ldapwhoami -h 127.0.0.1 -D "cn=admin,dc=cyberlab,dc=local" -w admin
```

### Wazuh Login Issues

**Reset Wazuh credentials:**

```bash
# Connect to Wazuh manager
docker exec wazuh.manager /var/ossec/bin/wazuh-control status

# Reset admin password
docker exec wazuh.manager /var/ossec/bin/wazuh_user_admin.sh -u admin -p MyNewPassword123
```

### Disk Space Issues

**Check Docker disk usage:**
```bash
docker system df
```

**Clean up unused data:**
```bash
# Remove unused volumes
docker volume prune

# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune
```

**Backup and clear logs:**
```bash
docker exec backup tar -czf /backups/old-logs.tar.gz /volumes/*/

# Truncate logs
docker exec <container> truncate -s 0 /var/log/app.log
```

---

## Documentation

### Architecture & Design

- **DEPLOYMENT_SUMMARY.md** - Complete deployment overview, service status, and commands
- **NETWORK_ACCESS_CONTROL.md** - Network policies and access control rules
- **SERVICE_ACCESS_MATRIX.md** - Quick reference for service accessibility
- **CONFIG_INVENTORY.md** - Configuration files inventory and recovery status

### Security & Implementation

- **SECURITY_ENHANCEMENTS_IMPLEMENTATION.md** - Security improvements documentation
- **TRAEFIK_SECURITY_UPDATE.md** - Traefik security hardening details
- **TRAEFIK_SERVICE_ROUTING.md** - Traefik routing configuration guide

### Integration & Recovery

- **LDAP_SERVICE_INTEGRATION_GUIDE.md** - LDAP setup and integration
- **LDAP_RECOVERY_GUIDE.md** - LDAP troubleshooting and recovery
- **SURICATA_OPENVPN_RECOVERY.md** - Suricata and OpenVPN recovery
- **NEUVECTOR_FIX.md** - NeuVector configuration fixes

### Testing & Configuration

- **DNS_TESTING_GUIDE.md** - DNS testing procedures and troubleshooting
- **DNS_HOSTS_CONFIG.md** - Host file configuration for domain access
- **DOCKER_COMPOSE_UPDATES.md** - Docker Compose changes documentation
- **CONFIGURATION_PERSISTENCE.md** - Volume and data persistence details
- **HOSTS_FILE_ENTRIES.txt** - Mac/Linux hosts file entries
- **RECOVERY_SUMMARY.md** - System recovery procedures

---

## Common Tasks

### Monitor Services in Real-Time

```bash
# Watch all services
watch -n 1 'docker-compose ps'

# Monitor resource usage
docker stats

# Follow logs
docker-compose logs -f --tail=50
```

### Back Up Configuration

```bash
# Backup all configs
tar -czf cyberlab-backup-$(date +%Y%m%d).tar.gz infra/

# Backup Docker volumes
docker exec backup tar -czf "/backups/volumes-$(date +%Y%m%d).tar.gz" /backup/
```

### Update Service Images

```bash
# Pull latest images
docker-compose pull

# Update and restart
docker-compose up -d --no-deps --build
```

### Reset Everything (WARNING: Deletes all data)

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: Deletes all data!)
docker-compose down -v

# Start fresh
docker-compose up -d
```

### Export Service Configurations

```bash
# Export Wazuh configuration
docker cp wazuh.manager:/var/ossec/etc/ossec.conf ./wazuh-backup.conf

# Export Suricata rules
docker cp suricata:/etc/suricata/rules/ ./suricata-rules-backup/

# Export Traefik configuration
docker cp traefik:/etc/traefik/ ./traefik-backup/
```

---

## Performance Tuning

### Memory Optimization

Edit `docker-compose.yml` to set service memory limits:

```yaml
wazuh.manager:
  mem_limit: 2g
  memswap_limit: 2g

suricata:
  mem_limit: 1g
```

### CPU Optimization

```yaml
services:
  wazuh.manager:
    cpus: '2'
    cpuset: '0-1'
```

### Log Rotation

Prevent logs from consuming disk space:

```bash
# Enable log rotation
docker run --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 ...
```

---

## Getting Help

### Documentation Links

- **Wazuh Documentation:** https://documentation.wazuh.com/
- **Suricata Documentation:** https://suricata.readthedocs.io/
- **NeuVector Documentation:** https://neuvector.com/docs/
- **Traefik Documentation:** https://doc.traefik.io/
- **OpenVPN Documentation:** https://openvpn.net/community-resources/

### Common Commands

```bash
# View all containers
docker ps -a

# View container details
docker inspect <container_name>

# View network details
docker network ls
docker network inspect <network_name>

# View volume details
docker volume ls
docker volume inspect <volume_name>

# Check Docker daemon logs (macOS)
log stream --predicate 'process == "dockerd"'
```

### Error Resources

Refer to the troubleshooting section and documentation files included in the project for detailed recovery procedures.

---

## Project Statistics

| Metric | Value |
|--------|-------|
| **Total Services** | 15 |
| **Network Segments** | 5 |
| **Configuration Lines** | 1,823+ |
| **Script Files** | 8 |
| **Detection Rules** | 300+ |
| **SSL Certificates** | 12+ |
| **Docker Volumes** | 25+ |
| **Backup Retention** | 30 days |
| **Memory (Running)** | ~8GB |
| **Storage (Volumes)** | ~50GB (with data) |

---

## License & Support

This project is designed for educational purposes in the CyberSecurity Diploma program at TAFE NSW.

For issues, questions, or improvements:
1. Check the documentation files in the project root
2. Review service-specific documentation in `infra/configs/`
3. Consult the troubleshooting guide in this README

---

## Quick Reference: Command Cheat Sheet

```bash
# Startup & Management
cd infra && docker-compose up -d          # Start all services
docker-compose down                        # Stop all services
docker-compose ps                          # Check status
docker-compose logs -f <service>           # View logs

# Service Operations
docker exec <service> <command>            # Execute in container
docker-compose restart <service>           # Restart service
docker-compose pull && docker-compose up -d  # Update services

# Scripts
cd infra/scripts
./test-dns.sh all                          # Test DNS
./verify-network-access.sh                 # Test connectivity
./seed-ldap.sh                             # Initialize LDAP
python3 test-dns-advanced.py --export json # Advanced DNS testing

# Troubleshooting
docker stats                               # Resource usage
docker volume ls                           # List volumes
docker network ls                          # List networks
docker logs <container>                    # View container logs

# Backup & Restore
docker exec backup ls /backups/            # List backups
docker exec backup tar -xzf /backups/file.tar.gz -C /backup/  # Restore

# Database Access
docker exec postgresql psql -U postgres -c "\l"  # List PG databases
docker exec mongodb mongosh -u root -p $PASS    # Connect to MongoDB
docker exec openldap ldapsearch -b "dc=cyberlab,dc=local" -x  # LDAP search
```

---

**Last Updated:** November 25, 2025
**Status:** ✅ Fully Operational
**Platform:** macOS/Linux with Docker

For detailed information on specific services, configuration, and recovery procedures, refer to the additional documentation files included in the project.
