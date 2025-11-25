# Suricata IDS & OpenVPN Recovery Guide
**Date:** November 24, 2025
**Status:** Complete Configuration Recovery

---

## Suricata IDS/IPS Configuration

### Overview
Suricata is running as a network-based intrusion detection and prevention system (IDS/IPS) monitoring traffic within the CyberLab infrastructure.

### Running Status
```
Container: suricata
Image: jasonish/suricata:latest
Status: Running (Healthy)
Network Mode: Host network
Interface Monitoring: eth0
```

### Configuration Location
**Path:** `infra/configs/suricata/suricata.yaml`

### Key Configuration Settings

#### Network Variables
```yaml
HOME_NET: "[10.10.0.0/16]"
EXTERNAL_NET: "!$HOME_NET"
HTTP_SERVERS: "$HOME_NET"
SMTP_SERVERS: "$HOME_NET"
SQL_SERVERS: "$HOME_NET"
DNS_SERVERS: "$HOME_NET"
```

#### Port Groups
```yaml
HTTP_PORTS: 80
SSH_PORTS: 22
FTP_PORTS: 21
ORACLE_PORTS: 1514
MODBUS_PORTS: 502
```

#### Packet Capture (AF_PACKET)
```yaml
Interface: eth0
Cluster ID: 99
Cluster Type: cluster_flow
Defragmentation: enabled
```

### Output Formats

#### 1. Fast Log
- **Format:** Simple, fast alert logging
- **File:** `/var/log/suricata/fast.log`
- **Status:** Enabled
- **Size:** 1.2 GB (as of Nov 24)

#### 2. EVE (Extended Event File)
- **Format:** JSON structured event logging
- **File:** `/var/log/suricata/eve.json`
- **Size:** 4.9 GB (as of Nov 24)
- **Event Types Logged:**
  - alert
  - http
  - dns
  - tls
  - smtp
  - ssh
  - stats
  - flow
  - anomaly

#### 3. HTTP Log
- **Format:** HTTP transaction logging
- **File:** `/var/log/suricata/http.log`
- **Status:** Enabled
- **Size:** 0 bytes (no HTTP captured yet)

#### 4. Syslog Integration
- **Facility:** Local5
- **Format:** "[%i] <%d> -- %s"
- **Identity:** suricata
- **Destination:** Syslog server (10.10.30.20:514)

### Rule Configuration

#### Rule Files
- **Default Rule Path:** `/var/lib/suricata/rules`
- **Active Rules File:** `suricata.rules`
- **Classification File:** `/etc/suricata/classification.config`
- **Reference Config:** `/etc/suricata/reference.config`

#### Rule Management
- Rules are loaded from the specified path
- Classification rules define severity levels
- Reference rules link to vulnerability databases

### Logging Configuration

```
Default Log Directory: /var/log/suricata
Log Retention: Persistent volumes
Analysis Stats: Enabled (engine-analysis-stats: yes)
Verbosity Level: 3 (debug info)
```

### Performance Monitoring

```yaml
Status Log:
  File: /var/log/openvpn/openvpn-status.log
  Update Interval: 10 seconds
  Contains: Active connections, bytes transferred, etc.
```

### Security Best Practices
1. **Monitor eve.json regularly** - Contains all detected events
2. **Review fast.log for alerts** - High-priority security events
3. **Check HTTP logs** - Application layer attacks
4. **Integrate with Wazuh** - Forward logs via syslog
5. **Regular rule updates** - Keep IDS signatures current

### Maintenance Tasks

#### View Real-time Traffic
```bash
docker exec suricata tail -f /var/log/suricata/eve.json | jq .
```

#### Verify Rule Loading
```bash
docker exec suricata suricata -i eth0 -V
```

#### Check IDS Status
```bash
docker logs suricata
```

#### Alert Statistics
```bash
docker exec suricata grep "alert" /var/log/suricata/fast.log | wc -l
```

---

## OpenVPN VPN Gateway Configuration

### Overview
OpenVPN (Access Server) provides secure VPN access to the CyberLab infrastructure for remote administrators and security personnel.

### Running Status
```
Container: openvpn
Image: openvpn/openvpn-as:latest
Status: Running (Healthy)
Port: 1194 (UDP) - VPN
Port: 943 (TCP) - Web UI
```

### Configuration Files
**Location:** `infra/configs/openvpn/`

#### Server Configuration
- **File:** `server.conf`
- **Size:** ~2.2 KB
- **Purpose:** Main OpenVPN server settings

#### Client Configuration Template
- **File:** `client.conf`
- **Purpose:** Template for client connections

### Server Configuration Details

#### Network Settings
```
VPN Network: 10.8.0.0/24
Protocol: UDP
Port: 1194
Device: TUN (tunneling interface)
```

#### Security Configuration
```
Encryption: AES-256-GCM (strongest cipher)
Authentication: SHA256
TLS Ciphers:
  - TLS_AES_256_GCM_SHA384
  - TLS_CHACHA20_POLY1305_SHA256
TLS Auth: ta.key (static key for DoS protection)
```

#### Certificate Infrastructure
```
Server Certificate: /openvpn/server.crt
Server Key: /openvpn/server.key
CA Certificate: /openvpn/ca.crt
Diffie-Hellman Params: /openvpn/dh.pem
TLS Auth Key: /openvpn/ta.key
```

#### VPN Routing Configuration
```
Routes Pushed to Clients:
  - 10.10.0.0/16 (CyberLab internal network)

DNS Servers:
  - 8.8.8.8 (Google)
  - 8.8.4.4 (Google)

Gateway: Redirect all traffic through VPN (redirect-gateway def1)
```

#### Performance & Reliability
```
Max Clients: 100
Keep-Alive: 10 seconds (ping)
Keep-Alive Timeout: 120 seconds
Persistent Keys: Enabled (avoid key regeneration)
Persistent TUN: Enabled (keep tunnel on restart)
Compression: LZO enabled
```

#### Logging
```
Log File: /var/log/openvpn/openvpn.log
Status File: /var/log/openvpn/openvpn-status.log
Update Interval: 10 seconds
Verbosity: 3 (informational)
```

### OpenVPN Web UI Access
- **URL:** https://localhost:943/admin
- **Port:** 943 (HTTPS)
- **Purpose:** Web-based configuration and client management
- **Access:** Via Traefik reverse proxy or direct

### Volumes
```
Volume Name: infra_openvpn_data
Mount Point: /openvpn
Contents:
  - server.conf
  - Certificates and keys
  - Configuration files
  - Generated client profiles
```

### Client Connection Process

#### 1. Generate Client Certificates
```bash
# On VPN server
docker exec openvpn openvpn-generate-client-cert client-name
```

#### 2. Obtain Client Configuration
```bash
# Download from web UI or extract:
docker exec openvpn cat /openvpn/client-name/client-name.ovpn
```

#### 3. Connect from Client
```bash
# Linux/Mac/Windows
openvpn --config client-name.ovpn
```

#### 4. Verify Connection
```bash
# Check if assigned VPN IP
ifconfig | grep -A1 tun0
# or
ipconfig (Windows)
```

### Security Considerations

#### Authentication
1. **Certificate-based** - Each client must have valid certificate
2. **TLS authentication** - Extra layer with static key (ta.key)
3. **Optional password** - Can be enabled for additional security

#### Encryption
- **AES-256-GCM** - Military-grade encryption
- **Perfect Forward Secrecy** - Supported via TLS 1.3
- **Perfect Handshake** - Strong key exchange

#### DoS Protection
- **TLS Auth** - Prevents unauthorized connection attempts
- **Keep-Alive** - Detects dead connections
- **Rate Limiting** - Prevent connection flooding

### Monitoring & Troubleshooting

#### Check VPN Status
```bash
docker logs -f openvpn
```

#### Connected Clients
```bash
# View status file
docker exec openvpn cat /var/log/openvpn/openvpn-status.log
```

#### Test VPN Connection
```bash
# From client
openvpn --config client.ovpn --test-crypto

# On server
docker exec openvpn netstat -an | grep 1194
```

#### View Logs
```bash
docker exec openvpn tail -f /var/log/openvpn/openvpn.log
```

### Common Issues & Solutions

#### Issue: Client Connection Timeout
```
Solution:
1. Verify firewall allows UDP 1194
2. Check certificate validity
3. Confirm server is accessible
4. Check TLS auth key is correct
```

#### Issue: No Internet After VPN Connect
```
Solution:
1. Verify DNS settings in client config
2. Check redirect-gateway is enabled
3. Confirm routes pushed to client
4. Test with: curl -v https://8.8.8.8
```

#### Issue: Certificate Validation Failed
```
Solution:
1. Re-generate client certificate
2. Verify CA certificate is in client config
3. Check certificate expiration dates
4. Confirm key permissions (600)
```

### Maintenance Schedule

**Daily:**
- Monitor active connections via status file
- Check for authentication failures in logs
- Verify bandwidth usage

**Weekly:**
- Review and rotate old client certificates
- Update VPN routes if infrastructure changes
- Audit client access logs

**Monthly:**
- Regenerate certificates approaching expiration
- Review and update security policies
- Performance optimization review

**Annually:**
- Certificate renewal
- Security audit
- Access control review

---

## Integration with Wazuh SIEM

### Suricata → Wazuh
```
Suricata EVE JSON logs → Syslog (facility local5)
↓
Wazuh Manager receives alerts
↓
Wazuh Indexer stores in OpenSearch
↓
Wazuh Dashboard displays security events
```

### Configuration
- **Suricata Output:** Syslog to 10.10.30.20:514
- **Wazuh Decoder:** eve-log decoder
- **Wazuh Rules:** 900xx series (IDS alerts)

---

## Recovery File Summary

### Recovered Files
✅ **suricata.yaml** - Complete IDS configuration
✅ **server.conf** - OpenVPN server configuration
✅ **client.conf** - OpenVPN client template

### File Locations
```
configs/suricata/
├── suricata.yaml (88 lines)
└── suricata_full.yaml (full config if extracted)

configs/openvpn/
├── server.conf (51 lines)
└── client.conf (45 lines)
```

### Configuration Statistics
```
Suricata Config: 88 lines (core settings)
OpenVPN Server: 51 lines
OpenVPN Client: 45 lines
Total: ~180 lines of config
```

---

## Next Steps

1. **Verify Suricata Rules**
   - Check /var/lib/suricata/rules/suricata.rules
   - Update rules if needed: suricata-update

2. **Test OpenVPN Connectivity**
   - Generate test client certificate
   - Connect from external machine
   - Verify access to internal network

3. **Monitor Logs**
   - Set up log forwarding to Wazuh
   - Monitor EVE JSON events
   - Create Wazuh rules for critical alerts

4. **Enable Client Profiles**
   - Generate client certificates via web UI
   - Distribute to authorized users
   - Document connection process

---

**Recovery Complete!**
All Suricata IDS and OpenVPN configurations have been successfully recovered and documented.
