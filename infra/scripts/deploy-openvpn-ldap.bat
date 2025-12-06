@echo off
REM ==============================================================================
REM OpenVPN + OpenLDAP Deployment Script for Windows Command Prompt
REM ==============================================================================
REM
REM Purpose: Automate deployment of OpenVPN with OpenLDAP integration
REM Supports: Windows 10/11 with Docker Desktop
REM
REM Usage:
REM   deploy-openvpn-ldap.bat [options]
REM
REM Options:
REM   /skip-passwords       Don't generate new passwords (use existing ones)
REM   /skip-ldap-seed       Don't seed LDAP with initial entries
REM   /help                 Show this help message
REM
REM ==============================================================================

setlocal enabledelayedexpansion

REM Colors are not directly supported in CMD, so we use simplified output

echo.
echo ======================================
echo OpenVPN + OpenLDAP Deployment
echo ======================================
echo.

REM Parse arguments
set SKIP_PASSWORDS=0
set SKIP_LDAP_SEED=0

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="/skip-passwords" (
    set SKIP_PASSWORDS=1
    shift
    goto parse_args
)
if /i "%~1"=="/skip-ldap-seed" (
    set SKIP_LDAP_SEED=1
    shift
    goto parse_args
)
if /i "%~1"=="/help" (
    call :show_help
    exit /b 0
)
echo Unknown option: %~1
call :show_help
exit /b 1

:args_done

REM Verify Docker is installed and running
echo [*] Checking Docker installation...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [!] Docker is not running. Please start Docker Desktop.
    exit /b 1
)
echo [+] Docker is running

REM Get infrastructure directory
for %%A in ("%~dp0..") do set INFRA_DIR=%%~fA
set SCRIPTS_DIR=%INFRA_DIR%\scripts
set SECRETS_DIR=%INFRA_DIR%\secrets

echo.
echo [*] Infra directory: %INFRA_DIR%
echo [*] Scripts directory: %SCRIPTS_DIR%
echo.

REM Create secrets directory if it doesn't exist
if not exist "%SECRETS_DIR%" (
    mkdir "%SECRETS_DIR%"
    echo [+] Created secrets directory
)

REM Generate passwords if needed
if %SKIP_PASSWORDS%==0 (
    echo [*] Setting up passwords...

    if not exist "%SECRETS_DIR%\ldap_admin_password" (
        echo [*] Generating LDAP admin password...
        REM Using PowerShell to generate random password
        powershell -Command "Write-Host ([System.Convert]::ToBase64String([System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(24))) | Out-File -Encoding ASCII -FilePath '%SECRETS_DIR%\ldap_admin_password'"
        echo [+] LDAP admin password created
    ) else (
        echo [!] LDAP admin password already exists
    )

    if not exist "%SECRETS_DIR%\openvpn_admin_password" (
        echo [*] Generating OpenVPN admin password...
        powershell -Command "Write-Host ([System.Convert]::ToBase64String([System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes(24))) | Out-File -Encoding ASCII -FilePath '%SECRETS_DIR%\openvpn_admin_password'"
        echo [+] OpenVPN admin password created
    ) else (
        echo [!] OpenVPN admin password already exists
    )
) else (
    echo [*] Skipping password generation
)

echo.
echo [*] Starting Docker services...

cd /d "%INFRA_DIR%"

echo [*] Starting OpenLDAP...
docker compose up -d openldap >nul 2>&1

echo [*] Starting OpenVPN...
docker compose up -d openvpn >nul 2>&1

echo [*] Starting Workstation...
docker compose up -d workstation >nul 2>&1

echo [*] Starting Traefik...
docker compose up -d traefik >nul 2>&1

echo [+] Docker services started

echo.
echo [*] Verifying services are running...

docker ps --format "{{.Names}}" | find "openldap" >nul
if errorlevel 1 (
    echo [!] OpenLDAP is not running
    exit /b 1
)
echo [+] OpenLDAP is running

docker ps --format "{{.Names}}" | find "openvpn" >nul
if errorlevel 1 (
    echo [!] OpenVPN is not running
    exit /b 1
)
echo [+] OpenVPN is running

echo.
echo [*] Waiting for services to be ready (this may take a minute)...
timeout /t 10 /nobreak

echo.
echo [*] Verifying LDAP connectivity...

for /f "tokens=*" %%A in ('type "%SECRETS_DIR%\ldap_admin_password"') do set LDAP_PW=%%A

docker exec openldap ldapsearch -x -H "ldap://127.0.0.1:389" -D "cn=admin,dc=cyberlab,dc=local" -w "%LDAP_PW%" -b "dc=cyberlab,dc=local" -s base "+" >nul 2>&1
if errorlevel 1 (
    echo [!] LDAP connectivity check failed
    exit /b 1
)
echo [+] LDAP connectivity verified

REM Run initialization scripts if available
if %SKIP_LDAP_SEED%==0 (
    if exist "%SCRIPTS_DIR%\seed-ldap.sh" (
        echo.
        echo [*] Seeding LDAP with initial entries...
        cd /d "%INFRA_DIR%"
        bash "%SCRIPTS_DIR%\seed-ldap.sh"
        if errorlevel 1 (
            echo [!] LDAP seeding failed
        ) else (
            echo [+] LDAP seeded successfully
        )
    )
)

if exist "%SCRIPTS_DIR%\init-openvpn.sh" (
    echo.
    echo [*] Initializing OpenVPN with LDAP...
    cd /d "%INFRA_DIR%"

    REM Detect host IP
    for /f "tokens=*" %%A in ('powershell -Command "Get-NetIPAddress -AddressFamily IPv4 -PrefixLength 24 | Select-Object -ExpandProperty IPAddress | Select-Object -First 1"') do set HOST_IP=%%A

    if "!HOST_IP!"=="" (
        set HOST_IP=127.0.0.1
    )

    echo [*] Detected host IP: !HOST_IP!

    set HOST_IP=!HOST_IP! & bash "%SCRIPTS_DIR%\init-openvpn.sh"
    if errorlevel 1 (
        echo [!] OpenVPN initialization failed
    ) else (
        echo [+] OpenVPN initialized successfully
    )
)

echo.
echo ======================================
echo [+] Deployment Complete!
echo ======================================
echo.
echo Services:
echo   * OpenVPN Admin: https://%HOST_IP%:943/admin
echo   * OpenLDAP Admin: https://ldap.cyberlab.local (via VPN)
echo.

if exist "%SECRETS_DIR%\ldap_admin_password" (
    echo Credentials:
    echo   * LDAP Admin Password:
    type "%SECRETS_DIR%\ldap_admin_password"
)

if exist "%SECRETS_DIR%\openvpn_admin_password" (
    echo   * OpenVPN Admin Password:
    type "%SECRETS_DIR%\openvpn_admin_password"
)

echo.
echo Next Steps:
echo   1. Access OpenVPN Admin UI: https://%HOST_IP%:943/admin
echo   2. Create LDAP users in phpLDAPadmin
echo   3. Download VPN client profile
echo   4. Connect to VPN with LDAP credentials
echo.

exit /b 0

:show_help
echo OpenVPN + OpenLDAP Deployment Script for Windows
echo.
echo Purpose: Automate deployment of OpenVPN with OpenLDAP integration
echo Supports: Windows 10/11 with Docker Desktop
echo.
echo Usage:
echo   deploy-openvpn-ldap.bat [options]
echo.
echo Options:
echo   /skip-passwords       Don't generate new passwords (use existing ones)
echo   /skip-ldap-seed       Don't seed LDAP with initial entries
echo   /help                 Show this help message
echo.
echo Examples:
echo   REM Full deployment with new passwords
echo   deploy-openvpn-ldap.bat
echo.
echo   REM Skip LDAP seeding (if already seeded)
echo   deploy-openvpn-ldap.bat /skip-ldap-seed
echo.
echo   REM Use existing passwords
echo   deploy-openvpn-ldap.bat /skip-passwords
echo.
