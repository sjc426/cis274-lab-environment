# =============================================================
# CIS274-Windows-Target-FA26
# Windows Server 2019 Eval - SMBv1 / EternalBlue
# Network: CIS274-Lab (Host-Only) | IP: 192.168.56.20
# =============================================================

packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "iso_path" {
  default = "D:/VMs/ISO/17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
}

variable "iso_checksum" {
  default = "none"
}

source "virtualbox-iso" "windows_target" {
  vm_name              = "CIS274-Windows-Target-FA26"
  iso_url              = "file:///${var.iso_path}"
  iso_checksum         = var.iso_checksum
  iso_interface        = "ide"

  cpus                 = 2
  memory               = 4096
  disk_size            = 61440

  guest_os_type        = "Windows2019_64"
  hard_drive_interface = "sata"
  guest_additions_mode = "disable"

  floppy_files = [
    "D:/CIS274-Packer/http/windows-target/Autounattend.xml",
    "D:/CIS274-Packer/scripts/windows-target/winrm-setup.ps1"
  ]

  boot_wait    = "5s"
  boot_command = ["<enter>"]

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = "CIS274admin!"
  winrm_timeout  = "120m"
  winrm_port     = 5985
  winrm_use_ssl  = false
  winrm_insecure = true

  output_directory = "D:/CIS274-Packer/builds/windows-target-tmp"
  export_opts = [
    "--manifest",
    "--vsys", "0",
    "--description", "CIS274 Windows Target FA26 - Win Server 2019 SMBv1 EternalBlue",
    "--version", "FA26"
  ]
  format = "ova"

  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  shutdown_timeout = "15m"

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--boot1", "dvd"],
    ["modifyvm", "{{.Name}}", "--boot2", "disk"],
    ["modifyvm", "{{.Name}}", "--boot3", "none"],
    ["modifyvm", "{{.Name}}", "--boot4", "none"],
    ["modifyvm", "{{.Name}}", "--audio", "none"],
    ["modifyvm", "{{.Name}}", "--usb", "off"],
    ["modifyvm", "{{.Name}}", "--vram", "32"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--nic1", "nat"],
    ["modifyvm", "{{.Name}}", "--nic2", "hostonly"],
    ["modifyvm", "{{.Name}}", "--hostonlyadapter2", "VirtualBox Host-Only Ethernet Adapter"],
    ["modifyvm", "{{.Name}}", "--clipboard-mode", "disabled"]
  ]
}

build {
  name    = "windows-target"
  sources = ["source.virtualbox-iso.windows_target"]

  provisioner "powershell" {
    script = "D:/CIS274-Packer/scripts/windows-target/provision.ps1"
  }

  post-processor "shell-local" {
    inline = [
      "move D:\\CIS274-Packer\\builds\\windows-target-tmp\\CIS274-Windows-Target-FA26.ova D:\\CIS274-Packer\\builds\\CIS274-Windows-Target-FA26.ova"
    ]
  }
}