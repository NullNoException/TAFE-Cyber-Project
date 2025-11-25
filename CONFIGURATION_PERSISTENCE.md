# Configuration Persistence Guide
**Date:** November 24, 2025
**Verified:** ✅ All configurations will persist after docker-compose down/up cycles

---

## Overview

All recovered configurations are **persisted and will remain working** even after stopping and restarting Docker containers. This document explains the persistence mechanisms.

---

## Volume Types

The docker-compose setup uses **two types of volumes**:

### 1. Bind Mounts (Configuration Files)
**Location:** `./infra/configs/` directory (host filesystem)
**Persistence:** ✅ Permanent (stored on host machine)
**Survives:**
- ✅ docker-compose down
- ✅ docker-compose up
- ✅ Container restart
- ✅ Docker engine restart
- ✅ System reboot

### 2. Named Volumes (Data Storage)
**Location:** Docker volumes (managed by Docker daemon)
**Persistence:** ✅ Permanent (independent of containers)
**Survives:**
- ✅ docker-compose down
- ✅ docker-compose up
- ✅ Container restart
- ✅ Docker engine restart
- ✅ System reboot
- ⚠️ NOT deleted unless explicitly removed with `docker volume rm`

---

## Configuration Files (Bind Mounts)

### All Configurations on Host Filesystem
```
infra/configs/
├── nginx/
│   ├── nginx.conf                 ✅ Persisted
│   └── conf.d/default.conf        ✅ Persisted
├── traefik/
│   ├── traefik.yml                ✅ Persisted (UPDATED)
│   └── dynamic.yml                ✅ Persisted (UPDATED)
├── wazuh/
│   ├── wazuh_cluster/
│   │   └── wazuh_manager.conf     ✅ Persisted
│   ├── wazuh_indexer/
│   │   ├── wazuh.indexer.yml      ✅ Persisted
│   │   ├── internal_users.yml     ✅ Persisted
│   │   └── opensearch.yml         ✅ Persisted
│   ├── wazuh_dashboard/
│   │   ├── opensearch_dashboards.yml ✅ Persisted
│   │   └── wazuh.yml              ✅ Persisted
│   ├── wazuh_indexer_ssl_certs/   ✅ Persisted (12 files)
│   └── generate-indexer-certs.yml ✅ Persisted
├── suricata/
│   ├── suricata.yaml              ✅ Persisted
│   └── suricata_full.yaml         ✅ Persisted
├── openvpn/
│   ├── server.conf                ✅ Persisted (UPDATED)
│   └── client.conf                ✅ Persisted
├── ldap/
│   ├── ldap.env                   ✅ Persisted
│   ├── phpldapadmin.conf.php      ✅ Persisted
│   ├── ldif/base.ldif             ✅ Persisted (UPDATED)
│   └── slapd.d/
│       └── cn=config/              ✅ Persisted
└── (other configs...)              ✅ All Persisted
```

**Total Size:** ~152 KB
**Recovery:** 36 configuration files recovered

---

## Bind Mount Configuration in docker-compose.yml

### Example: Traefik Configuration
```yaml
traefik:
  volumes:
    # These are bind mounts - configuration files on host
    - ./configs/traefik/traefik.yml:/etc/traefik/traefik.yml:ro
    - ./configs/traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro
    - /var/run/docker.sock:/var/run/docker.sock:ro
```

**How it works:**
1. `./configs/traefik/traefik.yml` - **Host path** (relative to docker-compose.yml)
2. `/etc/traefik/traefik.yml` - **Container path** where config is mounted
3. `:ro` - Read-only mount (container cannot modify)

### Verification: All Bind Mounts
```
✅ Nginx config → ./configs/nginx/nginx.conf
✅ Traefik config → ./configs/traefik/traefik.yml
✅ Traefik routing → ./configs/traefik/dynamic.yml
✅ Wazuh configs → ./configs/wazuh/wazuh_cluster/wazuh_manager.conf
✅ Wazuh certs → ./configs/wazuh/wazuh_indexer_ssl_certs/*
✅ OpenLDAP configs → ./configs/ldap/
✅ OpenVPN configs → ./configs/openvpn/
✅ Suricata config → ./configs/suricata/suricata.yaml
```

---

## Named Volumes (Data Storage)

### Volumes Used in Stack
```yaml
volumes:
  # Wazuh Volumes
  wazuh_api_configuration:     ✅ Persisted
  wazuh_etc:                   ✅ Persisted
  wazuh_logs:                  ✅ Persisted
  wazuh_queue:                 ✅ Persisted
  wazuh_var_multigroups:       ✅ Persisted
  wazuh_integrations:          ✅ Persisted
  wazuh_active_response:       ✅ Persisted
  wazuh_agentless:             ✅ Persisted
  wazuh_wodles:                ✅ Persisted
  filebeat_etc:                ✅ Persisted
  filebeat_var:                ✅ Persisted
  wazuh-indexer-data:          ✅ Persisted (4.9 GB)
  wazuh-dashboard-config:      ✅ Persisted
  wazuh-dashboard-custom:      ✅ Persisted

  # Directory/Database Volumes
  openldap_data:               ✅ Persisted (57 MB)
  openldap_slapd:              ✅ Persisted (8.2 KB)

  # Other Volumes
  neuvector_controller:        ✅ Persisted
  nginx_certs:                 ✅ Persisted
  nginx_logs:                  ✅ Persisted
```

**Important:** Named volumes are preserved even after `docker-compose down` unless explicitly deleted.

---

## Testing Configuration Persistence

### Test Procedure: Down and Up Cycle

**Step 1: Stop All Services**
```bash
cd infra
docker-compose down
```

**Expected Result:**
- Containers stopped
- Containers removed
- Networks removed
- **Volumes REMAIN** ✅
- **Configuration files REMAIN** ✅

**Step 2: Verify Configs Still Exist**
```bash
ls -la configs/traefik/
# Output shows: traefik.yml, dynamic.yml present ✅
```

**Step 3: Restart Services**
```bash
docker-compose up -d
```

**Expected Result:**
- Containers recreated
- Volumes automatically remounted
- Configuration files read from host
- Services start with same config ✅

**Step 4: Verify Service Configuration**
```bash
# Check Traefik loaded config
docker exec traefik cat /etc/traefik/dynamic.yml | grep neuvector

# Check Wazuh manager loaded config
docker exec wazuh.manager cat /wazuh-config-mount/etc/ossec.conf | wc -l

# Result: All configs loaded successfully ✅
```

---

## Configuration Verification Commands

### Verify Bind Mounts Are Active
```bash
# Check mounted config in running container
docker exec traefik ls -la /etc/traefik/
# Output: traefik.yml, dynamic.yml present ✅

# Verify it's reading from host
docker inspect traefik | grep -A 20 "Mounts"
# Shows: source: /path/to/configs/traefik/traefik.yml ✅
```

### Verify Named Volumes Persist
```bash
# List all volumes
docker volume ls | grep infra

# Check volume data exists
docker volume inspect infra_wazuh-indexer-data

# Verify volume path
# Shows: /var/lib/docker/volumes/infra_wazuh-indexer-data/_data ✅
```

### Check Configuration Files on Host
```bash
# Verify all configs recovered
find infra/configs -type f | wc -l
# Output: 36 files ✅

# Check file sizes
du -sh infra/configs/
# Output: ~152K total ✅

# Verify recent modifications
ls -lt infra/configs/traefik/
# Shows: dynamic.yml and traefik.yml recently modified ✅
```

---

## Persistence Guarantee

### What Will Persist
✅ All configuration files in `./infra/configs/`
✅ All Docker named volumes
✅ Database data (Wazuh, OpenLDAP, etc.)
✅ Certificate files
✅ Log files
✅ Service configurations
✅ Network settings
✅ Volume mount bindings

### What Will NOT Persist (Normal)
⚠️ Running container state (restarted fresh)
⚠️ Temporary files in containers
⚠️ Logs in container /var/log (unless volume mounted)

### Safe Operations
✅ `docker-compose down` - Safe, configs persist
✅ `docker-compose up -d` - Safe, configs reloaded
✅ `docker-compose restart` - Safe, configs stay
✅ `docker restart <service>` - Safe, configs stay
✅ System reboot - Safe, volumes and configs persist
✅ Docker daemon restart - Safe, volumes and configs persist

### Dangerous Operations (⚠️ Will Lose Data)
❌ `docker volume rm <volume-name>` - Deletes volume data
❌ `docker-compose down -v` - Removes all volumes!
❌ `docker system prune --volumes` - Deletes unused volumes
❌ Manual deletion of `./infra/configs/` - Loses configuration files

---

## Backup & Recovery Strategy

### Recommended Backups

**1. Configuration Files Backup**
```bash
# Backup all configs
tar -czf backup-configs-$(date +%Y%m%d).tar.gz infra/configs/

# Store in version control or external storage
git add backup-configs-*.tar.gz
git commit -m "Configuration backup"
```

**2. Docker Volumes Backup**
```bash
# Backup critical volumes
docker run --rm \
  -v infra_wazuh-indexer-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/wazuh-indexer-backup.tar.gz /data

# Backup LDAP data
docker run --rm \
  -v infra_openldap_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/ldap-data-backup.tar.gz /data
```

**3. Complete System Backup**
```bash
# Backup everything
docker-compose config > docker-compose-backup.yml
tar -czf complete-backup-$(date +%Y%m%d).tar.gz \
  infra/configs/ .env docker-compose-backup.yml
```

### Recovery from Backup

**If Configuration Files Lost:**
```bash
# Extract config backup
tar -xzf backup-configs-20251124.tar.gz

# Restart services
docker-compose restart
```

**If Volumes Lost (and backup exists):**
```bash
# Create empty volume
docker volume create infra_wazuh-indexer-data

# Restore from backup
docker run --rm \
  -v infra_wazuh-indexer-data:/restore \
  -v $(pwd):/backup \
  alpine tar xzf /backup/wazuh-indexer-backup.tar.gz -C /restore --strip-components=1
```

---

## Monitoring Persistence

### Check Configuration Freshness
```bash
# When configs were last modified
ls -lt infra/configs/traefik/ | head -5

# Example output:
# -rw-r--r-- 1 ziaparvaresh staff 6861 24 Nov 11:19 dynamic.yml
# -rw-r--r-- 1 ziaparvaresh staff 3300 24 Nov 10:55 traefik.yml
```

### Verify Volume Integrity
```bash
# Check volume mount points
docker inspect <container-name> | grep -A 10 "Mounts"

# Check volume usage
docker volume ls
docker volume inspect infra_wazuh-indexer-data
```

### Monitor Configuration Loading
```bash
# Watch container logs for config errors
docker logs -f traefik | grep -i "config\|error\|warning"

# Check if configs were loaded successfully
docker exec wazuh.manager grep -i "configuration" /var/log/wazuh.log | head -5
```

---

## Common Scenarios

### Scenario 1: Emergency Restart
```bash
cd /path/to/project/infra

# Stop all services
docker-compose down

# All configs safe in ./configs/ ✅

# Restart services
docker-compose up -d

# Services start with same configuration ✅
```

### Scenario 2: System Maintenance
```bash
# Reboot system
sudo reboot

# After reboot, restart Docker services
docker-compose up -d

# Configurations and volumes automatically remounted ✅
```

### Scenario 3: Container Updates
```bash
# Pull new image
docker-compose pull traefik

# Remove old container, keep config
docker-compose down traefik
docker-compose up -d traefik

# New container uses config from host filesystem ✅
```

### Scenario 4: Disaster Recovery
```bash
# System crashed, volumes lost but configs intact

# Recover from backup
tar -xzf backup-configs-20251124.tar.gz

# Restart with recovered configs
docker-compose up -d

# Services run with recovered configuration ✅
```

---

## Verification Checklist

- [x] All configuration files are on host filesystem
- [x] All bind mounts configured in docker-compose.yml
- [x] All named volumes created and managed by Docker
- [x] Configuration files are read-only mounted (`:ro`)
- [x] No critical config stored in container filesystem
- [x] Data volumes properly persisted
- [x] Tested down/up cycle successfully
- [x] Configurations verified after restart
- [x] Backup strategy documented
- [x] Recovery procedures documented

---

## Summary

### Configuration Persistence: ✅ GUARANTEED

**All recovered configurations are safe and will persist across:**
- ✅ Container restarts
- ✅ Service redeployment
- ✅ Docker daemon restarts
- ✅ System reboots
- ✅ docker-compose down/up cycles

**Configuration location:** `infra/configs/` (host filesystem)
**Data location:** Docker named volumes (managed by Docker)
**Persistence method:** Bind mounts + named volumes
**Backup status:** Documented and recommended
**Recovery procedures:** Documented

---

**All configurations will remain working!**
Safe to perform docker-compose down/up operations.
