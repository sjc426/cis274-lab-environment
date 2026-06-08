# =============================================================
# CIS274-Kali-FA26 (Full — with Ollama mistral:7b)
# Kali Linux — Attacker VM | IP: 192.168.56.100
# 10GB RAM | 4 CPU | 100GB disk | ~25GB OVA
# LESSON 10: format=ova in source block
# LESSON 7:  natpf1 (NIC1=NAT), watch log for port
# LESSON 13: isolinux BIOS, boot_wait=12s, <down><wait2><tab><wait2>
# LESSON 14: NIC1=NAT so HTTPIP=10.0.2.2, reachable by installer
# LESSON 15: ssh_timeout=3h — installer reboots mid-way, Packer must
#            survive the reboot and wait for SSH to come back up
# =============================================================

packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "kali_iso_url" {
  default = "https://cdimage.kali.org/kali-2026.1/kali-linux-2026.1-installer-amd64.iso"
}
variable "kali_iso_checksum" {
  default = "sha256:271477ad6ea2676c7346576971b9acc2d32fabd9c2bbaf0e6302397626149306"
}

source "virtualbox-iso" "kali_full" {
  vm_name              = "CIS274-Kali-FA26"
  iso_url              = var.kali_iso_url
  iso_checksum         = var.kali_iso_checksum
  iso_interface        = "sata"

  cpus                 = 4
  memory               = 10240
  disk_size            = 102400

  guest_os_type        = "Debian_64"
  hard_drive_interface = "sata"
  guest_additions_mode = "disable"

  format      = "ova"
  export_opts = ["--manifest", "--vsys", "0", "--description", "CIS274 Kali Attacker FA26", "--version", "1.0"]

  http_directory = "D:/CIS274-Packer/http/kali"
  http_port_min  = 8300
  http_port_max  = 8399

  output_directory = "D:/CIS274-Packer/builds/kali-tmp"

  boot_wait = "12s"
  boot_command = [
    "<down><wait2>",
    "<tab><wait2>",
    " auto=true priority=critical url=http://{{.HTTPIP}}:{{.HTTPPort}}/preseed.cfg DEBIAN_FRONTEND=noninteractive<enter>"
  ]

  communicator           = "ssh"
  ssh_username           = "student"
  ssh_password           = "CIS274student!"
  # LESSON 15: 3h timeout — installer takes ~40min, then reboots, then SSH comes up
  ssh_timeout            = "3h"
  ssh_handshake_attempts = 300

  shutdown_command = "echo 'CIS274student!' | sudo -S shutdown -P now"

  # LESSON 14: NIC1=NAT so installer reaches HTTP server at 10.0.2.2
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--audio", "none"],
    ["modifyvm", "{{.Name}}", "--usb", "off"],
    ["modifyvm", "{{.Name}}", "--vram", "32"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--nic1", "nat"],
    ["modifyvm", "{{.Name}}", "--nic2", "hostonly"],
    ["modifyvm", "{{.Name}}", "--hostonlyadapter2", "VirtualBox Host-Only Ethernet Adapter"]
  ]
}

build {
  name    = "kali-full"
  sources = ["source.virtualbox-iso.kali_full"]

  provisioner "file" {
    source      = "D:/CIS274-Packer/scripts/kali/"
    destination = "/tmp/"
  }

  provisioner "shell" {
    execute_command = "echo 'CIS274student!' | sudo -S bash {{.Path}}"
    script          = "D:/CIS274-Packer/scripts/kali/provision.sh"
    timeout         = "90m"
  }

  post-processor "shell-local" {
    inline = [
      "cmd /c move D:\\CIS274-Packer\\builds\\kali-tmp\\CIS274-Kali-FA26.ova D:\\CIS274-Packer\\builds\\CIS274-Kali-FA26.ova"
    ]
  }
}
