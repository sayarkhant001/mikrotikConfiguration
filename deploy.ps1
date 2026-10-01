# ==============================================================================
#            MIKROTIK INTERACTIVE ONE-COMMAND SITE DEPLOYER
#               Universal Captive Portal Provisioning Tool
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Banner {
    Clear-Host
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "     MIKROTIK UNIVERSAL CAPTIVE PORTAL SITE DEPLOYER             " -ForegroundColor Yellow
    Write-Host "      Supports ROS v6/v7 | All Routerboard Models | 10-10,000 IPs" -ForegroundColor DarkCyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-SubnetConfig([int]$count) {
    if ($count -lt 10) { $count = 10 }
    if ($count -gt 10000) { $count = 10000 }
    
    if ($count -le 240) {
        return @{
            Prefix    = 24
            Netmask   = "255.255.255.0"
            Network   = "10.10.10.0/24"
            NetAddr   = "10.10.10.0"
            Gateway   = "10.10.10.1"
            PoolStart = "10.10.10.10"
            PoolEnd   = "10.10.10.254"
            LeaseTime = "2h"
            Capacity  = 245
        }
    } elseif ($count -le 500) {
        return @{
            Prefix    = 23
            Netmask   = "255.255.254.0"
            Network   = "10.10.10.0/23"
            NetAddr   = "10.10.10.0"
            Gateway   = "10.10.10.1"
            PoolStart = "10.10.10.10"
            PoolEnd   = "10.10.11.250"
            LeaseTime = "2h"
            Capacity  = 501
        }
    } elseif ($count -le 1000) {
        return @{
            Prefix    = 22
            Netmask   = "255.255.252.0"
            Network   = "10.10.8.0/22"
            NetAddr   = "10.10.8.0"
            Gateway   = "10.10.8.1"
            PoolStart = "10.10.8.10"
            PoolEnd   = "10.10.11.250"
            LeaseTime = "1h"
            Capacity  = 1017
        }
    } elseif ($count -le 2000) {
        return @{
            Prefix    = 21
            Netmask   = "255.255.248.0"
            Network   = "10.10.0.0/21"
            NetAddr   = "10.10.0.0"
            Gateway   = "10.10.0.1"
            PoolStart = "10.10.0.10"
            PoolEnd   = "10.10.7.250"
            LeaseTime = "1h"
            Capacity  = 2033
        }
    } elseif ($count -le 4000) {
        return @{
            Prefix    = 20
            Netmask   = "255.255.240.0"
            Network   = "10.10.0.0/20"
            NetAddr   = "10.10.0.0"
            Gateway   = "10.10.0.1"
            PoolStart = "10.10.0.10"
            PoolEnd   = "10.10.15.250"
            LeaseTime = "45m"
            Capacity  = 4081
        }
    } elseif ($count -le 8000) {
        return @{
            Prefix    = 19
            Netmask   = "255.255.224.0"
            Network   = "10.10.0.0/19"
            NetAddr   = "10.10.0.0"
            Gateway   = "10.10.0.1"
            PoolStart = "10.10.0.10"
            PoolEnd   = "10.10.31.250"
            LeaseTime = "30m"
            Capacity  = 8177
        }
    } else {
        return @{
            Prefix    = 18
            Netmask   = "255.255.192.0"
            Network   = "10.10.0.0/18"
            NetAddr   = "10.10.0.0"
            Gateway   = "10.10.0.1"
            PoolStart = "10.10.0.10"
            PoolEnd   = "10.10.63.250"
            LeaseTime = "30m"
            Capacity  = 16369
        }
    }
}

Show-Banner

# ── 1. GATHER USER REQUIREMENTS ──────────────────────────────
Write-Host "[STEP 1/4] Site & Portal Selection" -ForegroundColor White
$SiteName = Read-Host "  Enter Site Name [Press ENTER for 'YadanarTun_WiFi']"
if ([string]::IsNullOrWhiteSpace($SiteName)) { $SiteName = "YadanarTun_WiFi" }

Write-Host "`n[STEP 2/4] Wireless & DNS Configuration" -ForegroundColor White
$Ssid = Read-Host "  Enter Wi-Fi SSID to broadcast [Press ENTER for '$SiteName']"
if ([string]::IsNullOrWhiteSpace($Ssid)) { $Ssid = $SiteName }

$DefaultDns = "$($SiteName.ToLower().Replace('_','')).wifi"
$DnsName = Read-Host "  Enter Captive Portal DNS name [Press ENTER for '$DefaultDns']"
if ([string]::IsNullOrWhiteSpace($DnsName)) { $DnsName = $DefaultDns }

Write-Host "`n[STEP 3/4] Capacity & Subnet Calculation (10 - 10,000 IPs)" -ForegroundColor White
$IpInput = Read-Host "  Enter number of concurrent users/IPs needed (10-10000) [Press ENTER for 250]"
[int]$ReqIps = 250
if (-not [string]::IsNullOrWhiteSpace($IpInput)) {
    if (-not [int]::TryParse($IpInput, [ref]$ReqIps) -or $ReqIps -lt 10 -or $ReqIps -gt 10000) {
        Write-Host "  ⚠️ Invalid number. Clamping to range 10-10000..." -ForegroundColor Yellow
        if ($ReqIps -lt 10) { $ReqIps = 10 }
        if ($ReqIps -gt 10000) { $ReqIps = 10000 }
    }
}

$Subnet = Get-SubnetConfig $ReqIps

Write-Host "`n  Calculated Subnet Architecture:" -ForegroundColor Green
Write-Host "  -------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Subnet Prefix : /$($Subnet.Prefix) (Netmask: $($Subnet.Netmask))" -ForegroundColor Cyan
Write-Host "  Network CIDR  : $($Subnet.Network)" -ForegroundColor Cyan
Write-Host "  Gateway IP    : $($Subnet.Gateway)" -ForegroundColor Cyan
Write-Host "  DHCP Pool     : $($Subnet.PoolStart) - $($Subnet.PoolEnd)" -ForegroundColor Cyan
Write-Host "  Total Usable  : $($Subnet.Capacity) concurrent client IPs" -ForegroundColor Cyan
Write-Host "  Lease Time    : $($Subnet.LeaseTime) (auto-optimized for density)" -ForegroundColor Cyan
Write-Host "  -------------------------------------------------------" -ForegroundColor DarkGray

Write-Host "`n[STEP 4/4] MikroTik Connection Details" -ForegroundColor White
$RouterIP = Read-Host "  Enter Router IP [Press ENTER for factory default 192.168.88.1]"
if ([string]::IsNullOrWhiteSpace($RouterIP)) { $RouterIP = "192.168.88.1" }

$RouterUser = "admin"
$RouterPass = Read-Host "  Enter Router Admin Password [Press ENTER if blank]"

# ── 2. DOWNLOAD ASSETS FROM GITHUB ────────────────────────────
$RepoOwner = "sayarkhant001"
$RepoName  = "mikrotikConfiguration"
$Branch    = "main"
$BaseUrl   = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"

$WorkDir = "$env:TEMP\mikrotik_deploy_$SiteName"
if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force }
New-Item -ItemType Directory -Path $WorkDir | Out-Null

Write-Host "`n>>> Fetching site assets from GitHub repository..." -ForegroundColor Cyan
$ZipUrl = "$BaseUrl/sites/$SiteName/hotspot.zip"
$ZipFile = "$WorkDir\hotspot.zip"
$UniversalRscUrl = "$BaseUrl/core/universal_setup.rsc"
$UniversalRscFile = "$WorkDir\universal_setup.rsc"

try {
    Write-Host "    Downloading: $ZipUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -UseBasicParsing
    Write-Host "    Portal archive downloaded successfully." -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Could not download hotspot.zip for '$SiteName'!" -ForegroundColor Red
    Write-Host "   Please ensure 'sites/$SiteName/hotspot.zip' exists in GitHub: $RepoOwner/$RepoName" -ForegroundColor Yellow
    return
}

try {
    Write-Host "    Downloading: $UniversalRscUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $UniversalRscUrl -OutFile $UniversalRscFile -UseBasicParsing
    Write-Host "    Universal setup script downloaded successfully." -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Could not download universal_setup.rsc from core!" -ForegroundColor Red
    return
}

# Extract portal archive
Write-Host "`n>>> Extracting captive portal files..." -ForegroundColor Cyan
$ExtractPath = "$WorkDir\hotspot"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractPath)

# ── 3. PREPARE CUSTOMIZED SETUP.RSC ───────────────────────────
$CustomSetupRsc = "$WorkDir\setup.rsc"
$HeaderConfig = @"
# --- AUTOMATICALLY INJECTED PARAMETERS BY DEPLOYER ---
:global siteName "$SiteName"
:global wifiSsid "$Ssid"
:global dnsName "$DnsName"
:global ipCapacity $($Subnet.Capacity)

"@

$CoreScript = Get-Content -Path $UniversalRscFile -Raw
$FinalScript = $HeaderConfig + "`n" + $CoreScript
Set-Content -Path $CustomSetupRsc -Value $FinalScript -Encoding ASCII

# ── 4. TRANSFER FILES TO MIKROTIK VIA FTP ──────────────────────
Write-Host "`n>>> Connecting to MikroTik at $RouterIP..." -ForegroundColor Cyan

# Test basic connectivity
$ping = Test-Connection -ComputerName $RouterIP -Count 1 -Quiet
if (-not $ping) {
    Write-Host "⚠️ Warning: Ping to $RouterIP failed. Ensure your PC is connected to the router!" -ForegroundColor Yellow
}

$ftpUri = "ftp://$RouterIP"
$cred = New-Object System.Net.NetworkCredential($RouterUser, $RouterPass)

Write-Host "    Uploading setup.rsc..." -ForegroundColor Gray
try {
    $client = [System.Net.FtpWebRequest]::Create("$ftpUri/setup.rsc")
    $client.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
    $client.Credentials = $cred
    $client.UseBinary = $true
    $client.Timeout = 10000
    $bytes = [System.IO.File]::ReadAllBytes($CustomSetupRsc)
    $stream = $client.GetRequestStream()
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
    Write-Host "    setup.rsc uploaded." -ForegroundColor Green
} catch {
    Write-Host "❌ FTP connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Verify Router IP and credentials. Make sure FTP service is enabled under /ip service." -ForegroundColor Yellow
    return
}

Write-Host "    Uploading portal files to router storage..." -ForegroundColor Gray
# Upload all portal files recursively
Get-ChildItem -Path $ExtractPath -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($ExtractPath.Length).Replace("\", "/")
    $target = "$ftpUri/hotspot$rel"
    
    if ($_.PSIsContainer) {
        try {
            $mk = [System.Net.FtpWebRequest]::Create($target)
            $mk.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
            $mk.Credentials = $cred
            $mk.GetResponse().Close()
        } catch {}
    } else {
        try {
            $up = [System.Net.FtpWebRequest]::Create($target)
            $up.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
            $up.Credentials = $cred
            $up.UseBinary = $true
            $b = [System.IO.File]::ReadAllBytes($_.FullName)
            $s = $up.GetRequestStream()
            $s.Write($b, 0, $b.Length)
            $s.Close()
        } catch {
            Write-Host "      Upload warning for $($_.Name): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
}
Write-Host "    All captive portal files uploaded successfully." -ForegroundColor Green

# ── 5. EXECUTION & DEVICE-MODE NOTICE ──────────────────────────
Write-Host "`n==================================================================" -ForegroundColor Green
Write-Host "             DEPLOYMENT ASSETS READY ON MIKROTIK                  " -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green

Write-Host "`nTo finish configuration, run this in MikroTik Terminal / Winbox:" -ForegroundColor White
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "   /import file-name=setup.rsc" -ForegroundColor Black -BackgroundColor Green
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray

Write-Host "`n[!] IMPORTANT FOR BRAND NEW ROUTERS (RouterOS v7.13+):" -ForegroundColor Yellow
Write-Host "    If your router is in 'mode: home' with device-mode restrictions," -ForegroundColor Gray
Write-Host "    setup.rsc will automatically initiate device-mode feature unlock." -ForegroundColor Gray
Write-Host "    To confirm, simply UNPLUG and RE-PLUG the router's power cord" -ForegroundColor Cyan
Write-Host "    within 3 minutes when prompted in terminal!" -ForegroundColor Cyan
Write-Host "`nDeployment completed successfully!`n" -ForegroundColor Green
