<#
.SYNOPSIS
    Setup Cloudflare Tunnel (cloudflared) on Windows 11 for Chemgraph
.DESCRIPTION
    This script installs cloudflared via winget, authenticates with Cloudflare,
    creates a tunnel, configures DNS, and installs it as a Windows Service.
.NOTES
    Author: Chemgraph Project
    Requires: PowerShell 7+, Administrator privileges, Cloudflare account
    Run: Right-click PowerShell -> "Run as Administrator" -> .\scripts\setup-tunnel.ps1 -Domain "chemgraph.ru" -Email "you@example.com"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Domain,

    [Parameter(Mandatory=$true)]
    [string]$Email,

    [string]$TunnelName = "chemgraph",

    [string]$LocalPort = "80",

    [switch]$ForceRecreate
)

# =============================================================================
# CONFIGURATION
# =============================================================================
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$CLOUDFLARED_DIR = "$env:USERPROFILE\.cloudflared"
$CONFIG_DIR = "$PSScriptRoot\..\config"
$CONFIG_FILE = "$CONFIG_DIR\cloudflared.yml"
$CREDENTIALS_FILE = "$CLOUDFLARED_DIR\$TunnelName.json"

# Colors
$GREEN = [ConsoleColor]::Green
$YELLOW = [ConsoleColor]::Yellow
$RED = [ConsoleColor]::Red
$CYAN = [ConsoleColor]::Cyan
$GRAY = [ConsoleColor]::DarkGray

function Write-Log {
    param([string]$Message, [ConsoleColor]$Color = $GRAY)
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-Log "✓ $Message" $GREEN }
function Write-Warning { param([string]$Message) Write-Log "⚠ $Message" $YELLOW }
function Write-ErrorMsg { param([string]$Message) Write-Log "✗ $Message" $RED }
function Write-Info { param([string]$Message) Write-Log "ℹ $Message" $CYAN }

# =============================================================================
# PRE-CHECKS
# =============================================================================
Write-Info "=== Chemgraph Cloudflare Tunnel Setup ==="
Write-Info "Domain: $Domain"
Write-Info "Tunnel Name: $TunnelName"
Write-Info "Local Port: $LocalPort"
Write-Info ""

# Check Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ErrorMsg "This script requires Administrator privileges!"
    Write-ErrorMsg "Right-click PowerShell and select 'Run as Administrator'"
    exit 1
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "PowerShell 7+ recommended. Current: $($PSVersionTable.PSVersion)"
}

# Check winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-ErrorMsg "winget not found. Install from Microsoft Store or GitHub."
    exit 1
}

# =============================================================================
# STEP 1: INSTALL CLOUDFLARED
# =============================================================================
Write-Info "=== Step 1: Installing cloudflared ==="

if (Get-Command cloudflared -ErrorAction SilentlyContinue) {
    $version = cloudflared --version
    Write-Success "cloudflared already installed: $version"
} else {
    Write-Info "Installing cloudflared via winget..."
    try {
        winget install --id Cloudflare.cloudflared --silent --accept-source-agreements --accept-package-agreements
        Write-Success "cloudflared installed"
    } catch {
        Write-ErrorMsg "Failed to install cloudflared via winget"
        Write-Info "Try manual install: https://github.com/cloudflare/cloudflared/releases"
        exit 1
    }
}

# Verify installation
$version = cloudflared --version
Write-Success "cloudflared version: $version"

# =============================================================================
# STEP 2: AUTHENTICATE WITH CLOUDFLARE
# =============================================================================
Write-Info "=== Step 2: Authenticating with Cloudflare ==="

if (Test-Path $CREDENTIALS_FILE -and -not $ForceRecreate) {
    Write-Warning "Credentials file exists: $CREDENTIALS_FILE"
    $choice = Read-Host "Re-authenticate? (y/N)"
    if ($choice -ne 'y' -and $choice -ne 'Y') {
        Write-Info "Skipping authentication"
    } else {
        cloudflared tunnel login
    }
} else {
    Write-Info "Opening browser for Cloudflare authentication..."
    Write-Info "Log in with your Cloudflare account and authorize the tunnel."
    cloudflared tunnel login
}

# Verify credentials
if (Test-Path $CREDENTIALS_FILE) {
    Write-Success "Credentials saved to $CREDENTIALS_FILE"
} else {
    Write-ErrorMsg "Authentication failed - credentials file not found"
    exit 1
}

# =============================================================================
# STEP 3: CREATE TUNNEL
# =============================================================================
Write-Info "=== Step 3: Creating tunnel '$TunnelName' ==="

$existingTunnel = cloudflared tunnel list | Select-String $TunnelName
if ($existingTunnel -and -not $ForceRecreate) {
    Write-Warning "Tunnel '$TunnelName' already exists"
    $tunnelId = ($existingTunnel -split '\s+')[0]
    Write-Info "Using existing tunnel ID: $tunnelId"
} else {
    if ($existingTunnel -and $ForceRecreate) {
        Write-Info "Deleting existing tunnel..."
        cloudflared tunnel delete -f $TunnelName
    }
    Write-Info "Creating new tunnel..."
    $output = cloudflared tunnel create $TunnelName
    Write-Success "Tunnel created: $output"
    $tunnelId = ($output -split ' ')[-1] -replace '[^a-f0-9-]', ''
}

# Verify tunnel ID format (UUID)
if ($tunnelId -notmatch '^[a-f0-9-]{36}$') {
    Write-Warning "Could not parse tunnel ID from output: $tunnelId"
    $tunnelId = Read-Host "Enter tunnel ID manually (UUID format)"
}

Write-Info "Tunnel ID: $tunnelId"

# =============================================================================
# STEP 4: CONFIGURE DNS
# =============================================================================
Write-Info "=== Step 4: Configuring DNS for $Domain ==="

Write-Info "Creating CNAME record: $Domain -> $tunnelId.cfargotunnel.com"
try {
    cloudflared tunnel route dns $TunnelName $Domain
    Write-Success "DNS record created"
} catch {
    Write-Warning "DNS creation failed (may already exist): $_"
    Write-Info "Verify in Cloudflare Dashboard: $Domain CNAME -> $tunnelId.cfargotunnel.com"
}

# =============================================================================
# STEP 5: CREATE CONFIG FILE
# =============================================================================
Write-Info "=== Step 5: Creating tunnel configuration ==="

$configContent = @"
tunnel: $tunnelId
credentials-file: $CREDENTIALS_FILE.replace('\', '/')
ingress:
  - hostname: $Domain
    service: http://localhost:$LocalPort
    originRequest:
      connectTimeout: 30s
      tlsTimeout: 10s
      tcpKeepAlive: 30s
      keepAliveTimeout: 90s
  - service: http_status:404
"@

# Ensure config directory exists
if (-not (Test-Path $CONFIG_DIR)) {
    New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
}

$configContent | Out-File -FilePath $CONFIG_FILE -Encoding utf8
Write-Success "Configuration written to $CONFIG_FILE"

# =============================================================================
# STEP 6: INSTALL AS WINDOWS SERVICE
# =============================================================================
Write-Info "=== Step 6: Installing as Windows Service ==="

$serviceName = "cloudflared-$TunnelName"

# Check if service exists
$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Warning "Service '$serviceName' already exists"
    $choice = Read-Host "Reinstall service? (y/N)"
    if ($choice -eq 'y' -or $choice -eq 'Y') {
        Write-Info "Stopping and removing existing service..."
        cloudflared service uninstall $serviceName 2>$null
        Stop-Service $serviceName -Force -ErrorAction SilentlyContinue
        sc.exe delete $serviceName 2>$null
    } else {
        Write-Info "Skipping service installation"
        goto :TestTunnel
    }
}

Write-Info "Installing service '$serviceName'..."
try {
    cloudflared service install --config $CONFIG_FILE
    Write-Success "Service installed"
} catch {
    Write-ErrorMsg "Service install failed: $_"
    Write-Info "Try manual: cloudflared service install --config $CONFIG_FILE"
    exit 1
}

# Configure service to start automatically
Set-Service -Name $serviceName -StartupType Automatic
Write-Success "Service configured for auto-start"

:TestTunnel
# =============================================================================
# STEP 7: TEST TUNNEL
# =============================================================================
Write-Info "=== Step 7: Testing tunnel ==="

Write-Info "Starting service..."
Start-Service $serviceName -ErrorAction SilentlyContinue

# Wait for service to start
Start-Sleep -Seconds 5

$status = (Get-Service $serviceName).Status
if ($status -eq 'Running') {
    Write-Success "Service is running"
} else {
    Write-Warning "Service status: $status"
    Write-Info "Check logs: Get-EventLog -LogName Application -Source cloudflared -Newest 20"
}

# Test local endpoint
Write-Info "Testing local endpoint (http://localhost:$LocalPort)..."
try {
    $response = Invoke-WebRequest -Uri "http://localhost:$LocalPort" -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Success "Local endpoint responding: $($response.StatusCode)"
} catch {
    Write-Warning "Local endpoint not responding (is docker stack running?): $_"
    Write-Info "Start with: make dev"
}

# Test tunnel endpoint (may take a moment to propagate)
Write-Info "Testing tunnel endpoint (https://$Domain)..."
Start-Sleep -Seconds 10
try {
    $response = Invoke-WebRequest -Uri "https://$Domain" -Method Head -TimeoutSec 15 -ErrorAction Stop -SkipCertificateCheck
    Write-Success "Tunnel endpoint responding: $($response.StatusCode)"
} catch {
    Write-Warning "Tunnel endpoint not ready yet (DNS propagation can take 1-2 min): $_"
    Write-Info "Test manually: curl -I https://$Domain"
}

# =============================================================================
# STEP 8: VERIFY SSL
# =============================================================================
Write-Info "=== Step 8: SSL Verification ==="
Write-Info "Check SSL Labs grade: https://www.ssllabs.com/ssltest/analyze.html?d=$Domain"
Write-Info "Expected: Grade A+ (Cloudflare handles TLS termination)"

# =============================================================================
# SUMMARY
# =============================================================================
Write-Info ""
Write-Info "=== SETUP COMPLETE ==="
Write-Success "Tunnel Name: $TunnelName"
Write-Success "Tunnel ID: $tunnelId"
Write-Success "Domain: $Domain"
Write-Success "Config: $CONFIG_FILE"
Write-Success "Credentials: $CREDENTIALS_FILE"
Write-Success "Service: $serviceName (Auto-start)"
Write-Info ""
Write-Info "Next steps:"
Write-Info "  1. Ensure docker stack is running: make dev"
Write-Info "  2. Test site: https://$Domain"
Write-Info "  3. Test admin: https://$Domain/ghost"
Write-Info "  4. Configure Ghost: Settings → General → Publication URL = https://$Domain"
Write-Info ""
Write-Info "Useful commands:"
Write-Info "  View logs: Get-EventLog -LogName Application -Source cloudflared -Newest 50"
Write-Info "  Restart: Restart-Service $serviceName"
Write-Info "  Stop: Stop-Service $serviceName"
Write-Info "  Uninstall: cloudflared service uninstall $serviceName"