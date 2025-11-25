# PowerShell script to initialize OpenVPN Access Server
# Equivalent to init-openvpn.sh for Windows environments

param(
    [string]$ContainerName = "openvpn",
    [string]$AdminUser = "openvpn",
    [string]$AdminPwFile = ".\secrets\openvpn_admin_password",
    [string]$ProfileOut = ".\openvpn-admin.ovpn",
    [string]$HostIP = ""
)

$ErrorActionPreference = "Stop"

# Read admin password from secret
if (-not (Test-Path $AdminPwFile)) {
    Write-Host "OpenVPN admin password not found: $AdminPwFile" -ForegroundColor Red
    Write-Host "Create it, e.g.:"
    Write-Host "  .\scripts\generate-passwords.sh | Select-String 'OPENVPN_ADMIN_PASSWORD' | ForEach-Object { `$_ -replace '.*=', '' } > $AdminPwFile"
    exit 1
}
$AdminPw = (Get-Content $AdminPwFile -Raw).Trim()

# Detect host IP if not provided
if ([string]::IsNullOrEmpty($HostIP)) {
    # On Windows, parse ipconfig output to get IPv4 address
    $ipconfigOutput = ipconfig
    $HostIP = ($ipconfigOutput | Select-String -Pattern 'IPv4 Address.*: (.+)' | 
               Select-Object -First 1 | 
               ForEach-Object { $_.Matches.Groups[1].Value.Trim() })
    
    if ([string]::IsNullOrEmpty($HostIP)) {
        $HostIP = "127.0.0.1"
    }
}

Write-Host "Using host IP: $HostIP" -ForegroundColor Cyan
Write-Host "Checking OpenVPN-AS container: $ContainerName"

# Check if container is running
$runningContainers = docker ps --format '{{.Names}}' 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Docker is not running or not accessible" -ForegroundColor Red
    exit 1
}

if ($runningContainers -notcontains $ContainerName) {
    Write-Host "Container '$ContainerName' is not running. Start it first, e.g.:" -ForegroundColor Red
    Write-Host "  cd infra; docker compose up -d openvpn"
    exit 1
}

$OasScriptsDir = "/usr/local/openvpn_as/scripts"

Write-Host "Waiting for OpenVPN-AS services inside container..."
$maxRetries = 20
$retries = 0
while ($retries -lt $maxRetries) {
    docker exec $ContainerName test -x "$OasScriptsDir/sacli" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        break
    }
    Start-Sleep -Seconds 3
    $retries++
}

if ($retries -ge $maxRetries) {
    Write-Host "Timeout waiting for OpenVPN-AS services" -ForegroundColor Red
    exit 1
}

Write-Host "Resetting admin password for user '$AdminUser' via sacli..."
docker exec $ContainerName "$OasScriptsDir/sacli" `
    --user $AdminUser `
    --new_pass $AdminPw `
    SetLocalPassword

Write-Host "Configuring host.name and sa.server.ip via sacli..."
docker exec $ContainerName "$OasScriptsDir/sacli" `
    --key "host.name" --value $HostIP ConfigPut
docker exec $ContainerName "$OasScriptsDir/sacli" `
    --key "sa.server.ip" --value $HostIP ConfigPut

Write-Host "Applying configuration and restarting OpenVPN-AS..."
docker exec $ContainerName "$OasScriptsDir/sacli" start 2>$null | Out-Null

Write-Host ""
Write-Host " OpenVPN-AS initialised via sacli." -ForegroundColor Green
Write-Host ""
Write-Host "Admin UI: https://$($HostIP):943/admin"
Write-Host "  Username: $AdminUser"
Write-Host "  Password: (from $AdminPwFile)"
Write-Host ""
Write-Host "You can override parameters, e.g.:"
Write-Host "  .\infra\scripts\init-openvpn.ps1 -HostIP 192.168.0.84 -AdminUser openvpn"
Write-Host ""

Write-Host "Configuring OpenVPN-AS to use LDAP auth against openldap..."

# Read LDAP admin password
$ldapAdminPwFile = ".\secrets\ldap_admin_password"
if (-not (Test-Path $ldapAdminPwFile)) {
    Write-Host "Warning: LDAP admin password file not found: $ldapAdminPwFile" -ForegroundColor Yellow
    Write-Host "Skipping LDAP configuration."
} else {
    $ldapAdminPw = Get-Content $ldapAdminPwFile -Raw | ForEach-Object { $_.Trim() }

    # Basic LDAP settings
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.module.type"     --value "ldap"     ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.ldap.0.server"  --value "openldap" ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.ldap.0.port"    --value "389"      ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.ldap.0.use_ssl" --value "false"    ConfigPut

    # Base DN and bind DN for your OpenLDAP
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.ldap.0.base_dn"   --value "dc=cyberlab,dc=local"          ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.ldap.0.bind_dn"   --value "cn=admin,dc=cyberlab,dc=local" ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.ldap.0.bind_pw"   --value $ldapAdminPw                    ConfigPut

    # User search filter (simple example: match uid)
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "auth.ldap.0.search_filter" --value "(uid=%USERNAME%)" ConfigPut

    Write-Host "Applying LDAP auth configuration and restarting OpenVPN-AS..."
    docker exec $ContainerName "$OasScriptsDir/sacli" start 2>$null | Out-Null

    Write-Host ""
    Write-Host "Configuring VPN routing through workstation..." -ForegroundColor Cyan
    
    # Configure VPN to push routes to internal networks via workstation gateway
    # VPN clients will route through 10.10.20.100 (workstation) to access all services
    
    Write-Host "Setting VPN network configuration..."
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "vpn.client.routing.reroute_gw" --value "false" ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "vpn.server.routing.private_network.0" --value "10.10.10.0/24" ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "vpn.server.routing.private_network.1" --value "10.10.20.0/24" ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "vpn.server.routing.private_network.2" --value "10.10.30.0/24" ConfigPut
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "vpn.server.routing.private_network.3" --value "10.10.40.0/24" ConfigPut
    
    # Set workstation as the gateway for VPN clients
    docker exec $ContainerName "$OasScriptsDir/sacli" --key "vpn.server.routing.gateway_access" --value "true" ConfigPut
    
    # Enable IP forwarding in workstation
    Write-Host "Enabling IP forwarding in workstation container..."
    docker exec workstation bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward" 2>$null | Out-Null
    
    # Add iptables rules in workstation for NAT/forwarding
    Write-Host "Configuring NAT rules in workstation..."
    docker exec workstation bash -c "iptables -t nat -A POSTROUTING -s 172.27.232.0/24 -o eth0 -j MASQUERADE" 2>$null | Out-Null
    docker exec workstation bash -c "iptables -A FORWARD -i eth0 -j ACCEPT" 2>$null | Out-Null
    docker exec workstation bash -c "iptables -A FORWARD -o eth0 -j ACCEPT" 2>$null | Out-Null
    
    Write-Host "Restarting OpenVPN-AS to apply routing configuration..."
    docker exec $ContainerName "$OasScriptsDir/sacli" start 2>$null | Out-Null
    
    Write-Host ""
    Write-Host "VPN routing configured successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1) Add hosts entries on your LOCAL machine (not in containers):" -ForegroundColor Yellow
    Write-Host "       10.10.10.5       traefik.cyberlab.local" -ForegroundColor White
    Write-Host "       10.10.30.25      wazuh.cyberlab.local" -ForegroundColor White
    Write-Host "       10.10.0.10       neuvector.cyberlab.local" -ForegroundColor White
    Write-Host "       10.10.20.30      ldap.cyberlab.local" -ForegroundColor White
    Write-Host "       10.10.10.50      dns.cyberlab.local" -ForegroundColor White
    Write-Host ""
    Write-Host "  2) Open the OpenVPN-AS admin UI:" -ForegroundColor Yellow
    Write-Host "       https://$($HostIP):943/admin"
    Write-Host "     Login with:"
    Write-Host "       Username: $AdminUser"
    Write-Host "       Password: contents of $AdminPwFile"
    Write-Host ""
    Write-Host "  3) Create LDAP users in phpLDAPadmin under dc=cyberlab,dc=local" -ForegroundColor Yellow
    Write-Host "     with a 'uid' attribute (e.g. uid=alice)."
    Write-Host ""
    Write-Host "  4) Test LDAP login to OpenVPN:" -ForegroundColor Yellow
    Write-Host "       - Use username = uid from LDAP (e.g. alice)"
    Write-Host "       - Use the LDAP user password you set in phpLDAPadmin."
    Write-Host ""
    Write-Host "  5) Download VPN client profile:" -ForegroundColor Yellow
    Write-Host "       https://$($HostIP):943/"
    Write-Host ""
    Write-Host "  6) Once connected via VPN, access services at:" -ForegroundColor Yellow
    Write-Host "       https://traefik.cyberlab.local (only accessible through VPN)"
    Write-Host "       https://wazuh.cyberlab.local (only accessible through VPN)"
    Write-Host "       https://neuvector.cyberlab.local (only accessible through VPN)"
    Write-Host "       https://ldap.cyberlab.local (only accessible through VPN)"
    Write-Host ""
}
