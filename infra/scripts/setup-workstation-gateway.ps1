# PowerShell script to configure workstation as VPN gateway
# This enables VPN users to access all internal services through the workstation

$ErrorActionPreference = "Stop"

$ContainerName = "workstation"

Write-Host "Configuring workstation as VPN gateway..." -ForegroundColor Cyan

# Check if container is running
$runningContainers = docker ps --format '{{.Names}}' 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker is not running or not accessible" -ForegroundColor Red
    exit 1
}

if ($runningContainers -notcontains $ContainerName) {
    Write-Host "Container '$ContainerName' is not running. Start it first:" -ForegroundColor Red
    Write-Host "  cd infra; docker compose up -d workstation"
    exit 1
}

Write-Host "Installing required packages in workstation..."
docker exec $ContainerName bash -c "apt-get update 2>/dev/null | grep -v 'GPG error' && apt-get install -y iptables iproute2 iputils-ping dnsutils curl 2>&1 | grep -v 'GPG error'" 2>$null | Out-Null

Write-Host "Enabling IP forwarding..."
docker exec $ContainerName bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

Write-Host "Configuring DNS to use dns-server container..."
# Configure DNS to use dns-server (10.10.20.50)
docker exec $ContainerName bash -c "echo 'nameserver 10.10.20.50' > /etc/resolv.conf"
docker exec $ContainerName bash -c "echo 'search cyberlab.local' >> /etc/resolv.conf"

Write-Host "Configuring iptables NAT rules..."
# Clear existing NAT rules
docker exec $ContainerName bash -c "iptables -t nat -F" 2>$null | Out-Null

# Enable MASQUERADE for VPN traffic
docker exec $ContainerName bash -c "iptables -t nat -A POSTROUTING -s 172.27.232.0/24 -j MASQUERADE"

# Allow forwarding
docker exec $ContainerName bash -c "iptables -P FORWARD ACCEPT"
docker exec $ContainerName bash -c "iptables -A FORWARD -i eth0 -j ACCEPT"
docker exec $ContainerName bash -c "iptables -A FORWARD -o eth0 -j ACCEPT"

# Allow forwarding between all network interfaces
docker exec $ContainerName bash -c "iptables -A FORWARD -i eth1 -j ACCEPT"
docker exec $ContainerName bash -c "iptables -A FORWARD -i eth2 -j ACCEPT"
docker exec $ContainerName bash -c "iptables -A FORWARD -i eth3 -j ACCEPT"

Write-Host ""
Write-Host "[OK] Workstation configured as VPN gateway successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Workstation IP addresses:" -ForegroundColor Cyan
Write-Host "  Internal Network (10.10.20.0/24): 10.10.20.100"
Write-Host "  DMZ Network (10.10.10.0/24):      10.10.10.100"
Write-Host "  Security Network (10.10.30.0/24): 10.10.30.100"
Write-Host "  Management Network (10.10.40.0/24): 10.10.40.100"
Write-Host ""
Write-Host "VPN users will route through this workstation to access all services."
Write-Host ""
Write-Host "Verify NAT rules:" -ForegroundColor Yellow
Write-Host "  docker exec workstation iptables -t nat -L -n -v"
Write-Host ""
Write-Host "Verify IP forwarding:" -ForegroundColor Yellow
Write-Host "  docker exec workstation cat /proc/sys/net/ipv4/ip_forward"
Write-Host ""
Write-Host "Verify DNS configuration:" -ForegroundColor Yellow
Write-Host "  docker exec workstation cat /etc/resolv.conf"
Write-Host "  docker exec workstation nslookup wazuh.cyberlab.local"
Write-Host ""

