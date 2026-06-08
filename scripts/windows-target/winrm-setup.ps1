# WinRM bootstrap — runs at first logon via Autounattend.xml
# Enables WinRM so Packer can communicate with the VM

Write-Host "[*] Enabling WinRM for Packer..."
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'
netsh advfirewall firewall add rule name="WinRM HTTP" dir=in action=allow protocol=TCP localport=5985
Set-Service WinRM -StartupType Automatic
Start-Service WinRM
Write-Host "[+] WinRM ready."