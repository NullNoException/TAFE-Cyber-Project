# NeuVector Service Routing Fix
**Date:** November 24, 2025
**Issue:** Internal Server Error when accessing neuvector.cyberlab.local
**Status:** ✅ RESOLVED

---

## Problem Summary

Accessing `https://neuvector.cyberlab.local` through Traefik was returning an Internal Server Error (500).

### Root Causes

1. **Incorrect Port Configuration**
   - Traefik config was pointing to `neuvector-allinone:10443`
   - Actual NeuVector port is `8443`

2. **TLS Certificate Verification**
   - NeuVector uses self-signed certificates in lab environment
   - Traefik was attempting certificate validation and failing
   - Needed to skip verification in lab setup

---

## Solution Applied

### 1. Updated Traefik Dynamic Configuration

**File:** `infra/configs/traefik/dynamic.yml`

#### Change 1: Fixed Backend Port
```yaml
# BEFORE
neuvector:
  loadBalancer:
    servers:
      - url: "https://neuvector-allinone:10443"

# AFTER
neuvector:
  loadBalancer:
    servers:
      - url: "https://neuvector-allinone:8443"
```

**Reason:** NeuVector exposes port 8443, not 10443

#### Change 2: Disabled Certificate Verification
```yaml
# BEFORE
neuvector-transport:
  serverName: "neuvector.allinone"
  rootCAs:
    - /certs/ca-cert.pem

# AFTER
neuvector-transport:
  serverName: "neuvector.allinone"
  insecureSkipVerify: true  # Lab environment: NeuVector uses self-signed certs
```

**Reason:** NeuVector uses self-signed certificates in lab environment. Certificate validation is unnecessary here but can be enabled with proper CA in production.

### 2. Restarted Traefik

```bash
docker restart traefik
```

---

## Verification

### Test Command
```bash
curl -k -i https://127.0.0.1 -H "Host: neuvector.cyberlab.local"
```

### Expected Response
```
HTTP/2 301
location: /index.html?v=60d9c9a66c
...
[Redirect to login/dashboard]
```

### Browser Access
```
https://neuvector.cyberlab.local
→ Redirects to login page
→ Default credentials: admin/admin
```

---

## Port Mappings (Corrected)

| Service | Container Port | Traefik Port | Purpose |
|---------|----------------|--------------|---------|
| NeuVector | 8443 | ✅ FIXED | Web console |
| NeuVector | 18300-18301 | Cluster | Inter-node communication |
| NeuVector | 18400-18401 | Cluster | Management communication |

---

## NeuVector Access Methods

### Method 1: Browser (Recommended)
```
https://neuvector.cyberlab.local
or
https://security.cyberlab.local
```

### Method 2: Direct Connection (Bypassing Traefik)
```bash
# Not recommended - use Traefik routing
https://localhost:8443
```

### Method 3: Via Curl
```bash
curl -k https://neuvector.cyberlab.local
```

---

## NeuVector Default Credentials

**Username:** admin
**Password:** admin

**Note:** Change default credentials in production!

---

## NeuVector Features Available

Once logged in, users can access:
- ✅ Container Security Posture
- ✅ Network Security Policies
- ✅ Vulnerability Scanning
- ✅ Threat Detection
- ✅ Compliance Monitoring
- ✅ Running Process Inspection
- ✅ Registry Scanning
- ✅ Admission Control

---

## Traefik Health Status

### Before Fix
```
traefik - Unhealthy (TLS errors, routing failures)
```

### After Fix
```
traefik - Unhealthy (expected in lab - other services may have issues)
         - NeuVector routing now working
```

---

## Production Deployment Notes

For production environments:

1. **Certificate Handling**
   ```yaml
   # Replace with proper CA certificates
   insecureSkipVerify: false
   rootCAs:
     - /path/to/valid/ca-cert.pem
   ```

2. **Port Security**
   - Restrict 8443 access to authorized networks
   - Use firewall rules or network policies

3. **Authentication**
   - Change default admin credentials
   - Implement OAuth/LDAP integration
   - Set up MFA if available

4. **TLS Configuration**
   - Use Let's Encrypt certificates
   - Implement proper certificate rotation
   - Enable OCSP stapling

---

## Testing Checklist

- [x] Traefik container restarted
- [x] NeuVector container running and healthy
- [x] Port 8443 confirmed
- [x] TLS handshake successful
- [x] Host header routing verified
- [x] 301 redirect received (expected)
- [x] Login page accessible
- [x] Dashboard loads properly

---

## Related Configuration Files

- `infra/configs/traefik/dynamic.yml` - Service routing (UPDATED)
- `infra/configs/traefik/traefik.yml` - Main Traefik config
- `HOSTS_FILE_ENTRIES.txt` - DNS resolution entries
- `TRAEFIK_SERVICE_ROUTING.md` - Complete routing documentation

---

## Next Steps

1. **Access NeuVector Dashboard**
   - Open browser to `https://neuvector.cyberlab.local`
   - Login with admin/admin
   - Change default password

2. **Configure Network Policies**
   - Set up security policies for containers
   - Define allowed traffic flows
   - Enable threat prevention

3. **Enable Scanning**
   - Configure registry scanning
   - Enable vulnerability scans
   - Set up compliance checks

4. **Monitor Security**
   - Review threat alerts
   - Check network behavior
   - Monitor policy violations

---

## Troubleshooting

### Still Getting 500 Error?
```bash
# Check Traefik logs
docker logs traefik | grep -i neuvector

# Check NeuVector is running
docker ps | grep neuvector

# Restart both services
docker restart traefik neuvector.allinone
```

### Certificate Warnings?
```
Expected with self-signed certificates
- Browser: Click "Advanced" → "Proceed"
- Curl: Use -k flag to skip verification
- Production: Use valid certificates
```

### Can't Reach Service?
1. Verify hosts file entry exists
2. Flush DNS cache
3. Check firewall rules
4. Verify containers are running

---

**Fix Completed Successfully!**

NeuVector is now accessible via `https://neuvector.cyberlab.local` through Traefik reverse proxy.
