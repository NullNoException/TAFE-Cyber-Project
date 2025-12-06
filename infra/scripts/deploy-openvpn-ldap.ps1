#################################################################################
# OpenVPN + OpenLDAP Deployment Script for Windows PowerShell
#
# Purpose: Automate complete deployment of OpenVPN with OpenLDAP integration
# Supports: Windows 10/11 with Docker Desktop and WSL2
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File deploy-openvpn-ldap.ps1 [options]
#
# Options:
#   -SkipPasswords      Don't generate new passwords (use existing ones)
#   -SkipLdapSeed       Don't seed LDAP with initial entries
#   -Help               Show this help message
#
#################################################################################

param(
    [switch]$SkipPasswords = $false,
    [switch]$SkipLdapSeed = $false,
    [switch]$Help = $false
)

# Set error action preference
$ErrorActionPreference = "Continue"

################################################################################
# Configuration
################################################################################

$InfraDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ScriptsDir = Join-Path $InfraDir "scripts"
$SecretsDir = Join-Path $InfraDir "secrets"
$ConfigsDir = Join-Path $InfraDir "configs"

# File paths
$LdapAdminPwFile = Join-Path $SecretsDir "ldap_admin_password"
$OpenVpnAdminPwFile = Join-Path $SecretsDir "openvpn_admin_password"
$DeployLog = Join-Path $InfraDir "deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

################################################################################
# Helper Functions
################################################################################

# Colors for output
function Write-Step {
    param([string]$Message)
    Write-Host "▶ $Message" -ForegroundColor Cyan
    Add-Content -Path $DeployLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
    Add-Content -Path $DeployLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ✓ $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
    Add-Content -Path $DeployLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ✗ $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
    Add-Content -Path $DeployLog -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ⚠ $Message"
}

# Check if command exists
function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Check if Docker is running
function Test-Docker {
    Write-Step "Checking Docker installation..."

    if (-not (Test-Command docker)) {
        Write-Error "Docker is not installed. Please install Docker Desktop for Windows."
        return $false
    }

    try {
        $null = docker ps 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Docker is running"
            return $true
        }
    }
    catch { }

    Write-Error "Docker daemon is not running. Please start Docker Desktop."
    return $false
}

# Check if container is running
function Test-Container {
    param([string]$ContainerName)

    try {
        $containers = docker ps --format "{{.Names}}" 2>$null
        if ($containers -match "^$ContainerName$") {
            Write-Success "$ContainerName is running"
            return $true
        }
    }
    catch { }

    Write-Error "$ContainerName is not running"
    return $false
}

# Wait for container to be ready
function Wait-Container {
    param(
        [string]$ContainerName,
        [int]$Port,
        [int]$Timeout = 300
    )

    Write-Step "Waiting for $ContainerName to be ready (listening on port $Port)..."
    $elapsed = 0

    while ($elapsed -lt $Timeout) {
        try {
            $null = docker exec $ContainerName nc -z localhost $Port 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$ContainerName is ready"
                return $true
            }
        }
        catch { }

        Start-Sleep -Seconds 2
        $elapsed += 2
        Write-Host "  Waiting... ${elapsed}s/${Timeout}s`r" -NoNewline
    }

    Write-Host ""
    Write-Error "Timeout waiting for $ContainerName"
    return $false
}

# Get local IP address
function Get-LocalIP {
    try {
        # Try to get the IP address of the host machine
        $ip = (Test-Connection -ComputerName $(hostname) -Count 1 -ErrorAction Stop).IPV4Address.IPAddressToString
        return $ip
    }
    catch {
        # Fallback: get the Docker host IP
        try {
            $ip = docker inspect -f "{{ .NetworkSettings.Gateway }}" openldap 2>$null
            if ($ip) {
                return $ip
            }
        }
        catch { }

        # Final fallback
        return "127.0.0.1"
    }
}

################################################################################
# Deployment Functions
################################################################################

# Generate passwords if they don't exist
function Initialize-Passwords {
    if ($SkipPasswords) {
        Write-Step "Skipping password generation (using existing passwords)"
        return $true
    }

    Write-Step "Setting up passwords..."

    if (-not (Test-Path $SecretsDir)) {
        New-Item -ItemType Directory -Path $SecretsDir -Force | Out-Null
        Write-Success "Created secrets directory: $SecretsDir"
    }

    # Generate LDAP admin password if missing
    if (-not (Test-Path $LdapAdminPwFile)) {
        Write-Step "Generating LDAP admin password..."
        $LdapPassword = [System.Convert]::ToBase64String(
            [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(24)
        )
        Set-Content -Path $LdapAdminPwFile -Value $LdapPassword -Force
        Write-Success "LDAP admin password created: $LdapAdminPwFile"
    }
    else {
        Write-Warning "LDAP admin password already exists"
    }

    # Generate OpenVPN admin password if missing
    if (-not (Test-Path $OpenVpnAdminPwFile)) {
        Write-Step "Generating OpenVPN admin password..."
        $OpenVpnPassword = [System.Convert]::ToBase64String(
            [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(24)
        )
        Set-Content -Path $OpenVpnAdminPwFile -Value $OpenVpnPassword -Force
        Write-Success "OpenVPN admin password created: $OpenVpnAdminPwFile"
    }
    else {
        Write-Warning "OpenVPN admin password already exists"
    }

    return $true
}

# Start Docker services
function Start-Services {
    Write-Step "Starting Docker services..."

    Push-Location $InfraDir
    try {
        Write-Step "Starting OpenLDAP..."
        docker compose up -d openldap 2>&1 | Out-Null

        Write-Step "Starting OpenVPN..."
        docker compose up -d openvpn 2>&1 | Out-Null

        Write-Step "Starting Workstation..."
        docker compose up -d workstation 2>&1 | Out-Null

        Write-Step "Starting Traefik..."
        docker compose up -d traefik 2>&1 | Out-Null

        Write-Success "Docker services started"
        return $true
    }
    catch {
        Write-Error "Failed to start services: $_"
        return $false
    }
    finally {
        Pop-Location
    }
}

# Verify all services are running
function Test-Services {
    Write-Step "Verifying services are running..."

    $failed = 0

    if (-not (Test-Container "openldap")) {
        $failed++
    }

    if (-not (Test-Container "openvpn")) {
        $failed++
    }

    if (-not (Test-Container "workstation")) {
        $failed++
    }

    if ($failed -gt 0) {
        Write-Error "$failed service(s) not running"
        return $false
    }

    Write-Success "All services are running"
    return $true
}

# Wait for services to be ready
function Wait-Services {
    Write-Step "Waiting for services to be fully initialized..."

    if (-not (Wait-Container "openldap" 389)) {
        Write-Error "OpenLDAP failed to start"
        return $false
    }

    Start-Sleep -Seconds 5
    Write-Success "Services are ready"
    return $true
}

# Seed LDAP with initial data
function Initialize-Ldap {
    if ($SkipLdapSeed) {
        Write-Step "Skipping LDAP seeding"
        return $true
    }

    Write-Step "Seeding LDAP with initial entries..."

    $SeedScript = Join-Path $ScriptsDir "seed-ldap.sh"

    if (-not (Test-Path $SeedScript)) {
        Write-Error "seed-ldap.sh script not found"
        return $false
    }

    Push-Location $InfraDir
    try {
        # Convert Windows path to WSL path if running under WSL
        if ($env:WSL_DISTRO_NAME) {
            bash $SeedScript 2>&1 | ForEach-Object { Add-Content -Path $DeployLog -Value $_ }
        }
        else {
            # Running native Windows, use bash from Git Bash or WSL
            bash $SeedScript 2>&1 | ForEach-Object { Add-Content -Path $DeployLog -Value $_ }
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Success "LDAP seeded successfully"
            return $true
        }
        else {
            Write-Error "Failed to seed LDAP"
            return $false
        }
    }
    catch {
        Write-Error "Failed to seed LDAP: $_"
        return $false
    }
    finally {
        Pop-Location
    }
}

# Initialize OpenVPN with LDAP
function Initialize-OpenVPN {
    Write-Step "Initializing OpenVPN with LDAP authentication..."

    $InitScript = Join-Path $ScriptsDir "init-openvpn.sh"

    if (-not (Test-Path $InitScript)) {
        Write-Error "init-openvpn.sh script not found"
        return $false
    }

    $HostIP = Get-LocalIP
    Write-Success "Detected host IP: $HostIP"

    Push-Location $InfraDir
    try {
        $env:HOST_IP = $HostIP

        if ($env:WSL_DISTRO_NAME) {
            bash $InitScript 2>&1 | ForEach-Object { Add-Content -Path $DeployLog -Value $_ }
        }
        else {
            bash $InitScript 2>&1 | ForEach-Object { Add-Content -Path $DeployLog -Value $_ }
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Success "OpenVPN initialized successfully"
            return $true
        }
        else {
            Write-Error "Failed to initialize OpenVPN"
            return $false
        }
    }
    catch {
        Write-Error "Failed to initialize OpenVPN: $_"
        return $false
    }
    finally {
        Pop-Location
        Remove-Item env:HOST_IP -ErrorAction SilentlyContinue
    }
}

# Setup workstation as VPN gateway
function Initialize-WorkstationGateway {
    Write-Step "Setting up workstation as VPN gateway..."

    $GatewayScript = Join-Path $ScriptsDir "setup-workstation-gateway.sh"

    if (-not (Test-Path $GatewayScript)) {
        Write-Warning "setup-workstation-gateway.sh script not found, skipping"
        return $true
    }

    Push-Location $InfraDir
    try {
        if ($env:WSL_DISTRO_NAME) {
            bash $GatewayScript 2>&1 | ForEach-Object { Add-Content -Path $DeployLog -Value $_ }
        }
        else {
            bash $GatewayScript 2>&1 | ForEach-Object { Add-Content -Path $DeployLog -Value $_ }
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Workstation gateway configured"
            return $true
        }
        else {
            Write-Warning "Failed to configure workstation gateway"
            return $true  # Don't fail deployment
        }
    }
    catch {
        Write-Warning "Failed to configure workstation gateway: $_"
        return $true
    }
    finally {
        Pop-Location
    }
}

# Verify LDAP connectivity
function Test-Ldap {
    Write-Step "Verifying LDAP connectivity..."

    if (-not (Test-Container "openldap")) {
        Write-Error "OpenLDAP container not running"
        return $false
    }

    if (-not (Test-Path $LdapAdminPwFile)) {
        Write-Error "LDAP password file not found"
        return $false
    }

    $LdapPassword = Get-Content -Path $LdapAdminPwFile

    try {
        $null = docker exec openldap ldapsearch -x `
            -H "ldap://127.0.0.1:389" `
            -D "cn=admin,dc=cyberlab,dc=local" `
            -w $LdapPassword `
            -b "dc=cyberlab,dc=local" `
            -s base "+" 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Success "LDAP connectivity verified"
            return $true
        }
    }
    catch { }

    Write-Error "LDAP connectivity check failed"
    return $false
}

# Display deployment summary
function Show-Summary {
    Write-Step "Deployment Summary"

    $HostIP = Get-LocalIP
    $LdapPassword = Get-Content -Path $LdapAdminPwFile
    $OpenVpnPassword = Get-Content -Path $OpenVpnAdminPwFile

    Write-Host ""
    Write-Host "✓ Deployment Complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Services:" -ForegroundColor Green
    Write-Host "  • OpenLDAP Admin: https://ldap.cyberlab.local (via VPN only)"
    Write-Host "  • OpenVPN Admin:  https://${HostIP}:943/admin"
    Write-Host "  • Traefik:        https://traefik.cyberlab.local (via VPN only)"
    Write-Host ""
    Write-Host "Credentials:" -ForegroundColor Green
    Write-Host "  • LDAP Admin Password:    $LdapPassword"
    Write-Host "  • OpenVPN Admin Password: $OpenVpnPassword"
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Green
    Write-Host "  1. Access OpenVPN Admin UI:"
    Write-Host "     https://${HostIP}:943/admin"
    Write-Host "     Username: openvpn"
    Write-Host "     Password: (from $OpenVpnAdminPwFile)"
    Write-Host ""
    Write-Host "  2. Create LDAP users in phpLDAPadmin:"
    Write-Host "     • Navigate to ou=users,dc=cyberlab,dc=local"
    Write-Host "     • Create users with 'uid' attribute"
    Write-Host "     • Example: uid=alice"
    Write-Host ""
    Write-Host "  3. Download VPN client profile:"
    Write-Host "     https://${HostIP}:943/"
    Write-Host ""
    Write-Host "  4. Connect to VPN with LDAP credentials:"
    Write-Host "     Username: <ldap_uid>"
    Write-Host "     Password: <ldap_password>"
    Write-Host ""
    Write-Host "  5. Access internal services (when connected to VPN):"
    Write-Host "     https://traefik.cyberlab.local"
    Write-Host "     https://ldap.cyberlab.local"
    Write-Host "     https://wazuh.cyberlab.local"
    Write-Host ""
    Write-Host "Logs:" -ForegroundColor Green
    Write-Host "  Deployment log: $DeployLog"
    Write-Host ""
}

# Show help
function Show-Help {
    Write-Host @"
OpenVPN + OpenLDAP Deployment Script for Windows PowerShell

Purpose: Automate complete deployment of OpenVPN with OpenLDAP integration
Supports: Windows 10/11 with Docker Desktop and WSL2

Usage:
  powershell -ExecutionPolicy Bypass -File deploy-openvpn-ldap.ps1 [options]

Options:
  -SkipPasswords      Don't generate new passwords (use existing ones)
  -SkipLdapSeed       Don't seed LDAP with initial entries
  -Help               Show this help message

Examples:
  # Full deployment with new passwords
  powershell -ExecutionPolicy Bypass -File deploy-openvpn-ldap.ps1

  # Skip LDAP seeding (if already seeded)
  powershell -ExecutionPolicy Bypass -File deploy-openvpn-ldap.ps1 -SkipLdapSeed

  # Use existing passwords
  powershell -ExecutionPolicy Bypass -File deploy-openvpn-ldap.ps1 -SkipPasswords
"@
}

################################################################################
# Main Execution
################################################################################

if ($Help) {
    Show-Help
    exit 0
}

# Create log file
New-Item -Path $DeployLog -ItemType File -Force | Out-Null

# Header
Add-Content -Path $DeployLog -Value "========================================"
Add-Content -Path $DeployLog -Value "OpenVPN + OpenLDAP Deployment Script"
Add-Content -Path $DeployLog -Value "========================================"
Add-Content -Path $DeployLog -Value "Start time: $(Get-Date)"
Add-Content -Path $DeployLog -Value "Platform: Windows"
Add-Content -Path $DeployLog -Value "Infra directory: $InfraDir"

Write-Step "Starting OpenVPN + OpenLDAP deployment..."

# Execute deployment steps
$failed = 0

if (-not (Test-Docker)) { $failed++ }
if (-not (Initialize-Passwords)) { $failed++ }
if (-not (Start-Services)) { $failed++ }
if (-not (Test-Services)) { $failed++ }
if (-not (Wait-Services)) { $failed++ }
if (-not (Test-Ldap)) { $failed++ }
if (-not (Initialize-Ldap)) { $failed++ }
if (-not (Initialize-OpenVPN)) { $failed++ }
if (-not (Initialize-WorkstationGateway)) {
    Write-Warning "Workstation gateway setup had issues"
}

# Final summary
if ($failed -eq 0) {
    Add-Content -Path $DeployLog -Value "Deployment completed successfully"
    Show-Summary
    exit 0
}
else {
    Add-Content -Path $DeployLog -Value "Deployment completed with $failed error(s)"
    Write-Error "Deployment had $failed error(s). Check the log: $DeployLog"
    exit 1
}
