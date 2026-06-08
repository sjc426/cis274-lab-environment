# =============================================================
# CIS274-Windows-Target-FA26 - Provision Script
# Enables SMBv1, disables firewall, sets static IP on host-only NIC
# EternalBlue target: MS17-010 (NO patches applied)
# =============================================================

Write-Host "[*] CIS274 Windows Target Provisioner starting..."
Set-ExecutionPolicy Unrestricted -Force -ErrorAction SilentlyContinue

# ---- Disable Windows Firewall (lab only) --------------------
Write-Host "[*] Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
netsh advfirewall set allprofiles state off

# ---- Enable SMBv1 (EternalBlue target) ----------------------
Write-Host "[*] Enabling SMBv1..."
Set-SmbServerConfiguration -EnableSMB1Protocol $true -Force -ErrorAction SilentlyContinue
sc.exe config lanmanserver start= auto
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 1 -Type DWORD

# ---- Disable automatic updates (keep unpatched) -------------
Write-Host "[*] Disabling Windows Update..."
Set-Service wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 1 /f

# ---- Static IP on host-only NIC (NIC2 - NOT the NAT adapter) ----
Write-Host "[*] Setting static IP 192.168.56.20 on host-only adapter..."
$hoAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
    $ip = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    if ($ip -notlike "10.0.2.*" -and $ip -notlike "169.254.*") { $_ }
} | Select-Object -First 1

if ($hoAdapter) {
    Write-Host "[*] Found host-only adapter: $($hoAdapter.Name)"
    Remove-NetIPAddress -InterfaceIndex $hoAdapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceIndex $hoAdapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceIndex $hoAdapter.ifIndex -IPAddress 192.168.56.20 -PrefixLength 24 -ErrorAction SilentlyContinue
    Set-DnsClientServerAddress -InterfaceIndex $hoAdapter.ifIndex -ServerAddresses 8.8.8.8 -ErrorAction SilentlyContinue
    Write-Host "[+] Static IP set: 192.168.56.20"
} else {
    Write-Host "[!] Host-only adapter not found - skipping static IP"
}

# ---- Rename computer ----------------------------------------
Rename-Computer -NewName "WIN-TARGET" -Force -ErrorAction SilentlyContinue

# ---- Create student user ------------------------------------
Write-Host "[*] Creating student user..."
$pw = ConvertTo-SecureString "CIS274student!" -AsPlainText -Force
New-LocalUser -Name "student" -Password $pw -FullName "CIS274 Student" -Description "Lab student account" -ErrorAction SilentlyContinue
Add-LocalGroupMember -Group "Administrators" -Member "student" -ErrorAction SilentlyContinue

# ---- Enable RDP ---------------------------------------------
Write-Host "[*] Enabling RDP..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

# ---- Lab banner ---------------------------------------------
Write-Host "[*] Setting lab banner..."
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v legalnoticecaption /t REG_SZ /d "CIS 274 - Windows Target" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v legalnoticetext /t REG_SZ /d "Windows Server 2019 - IP 192.168.56.20 - CIS274 FA26 - SMBv1 ENABLED" /f

# ---- Disable UAC --------------------------------------------
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f

# ---- Cleanup ------------------------------------------------
Write-Host "[*] Cleaning up..."
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

Write-Host "[+] Provisioning complete! Rebooting..."
Restart-Computer -Force