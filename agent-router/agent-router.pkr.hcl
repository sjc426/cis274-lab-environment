# =============================================================
# CIS274-AgentRouter-FA26 -- Ubuntu 24.04 LTS
# LESSON 2 FIX: format=ova in source block for native export
# shell-local only does cmd move to rename to final destination
# =============================================================

packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "iso_url" {
  default = "D:/CIS274-Packer/linux-target/packer_cache/404079b253c03df4faee35898313e7c4d9dde17b.iso"
}
variable "iso_checksum" {
  default = "sha256:e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"
}

source "virtualbox-iso" "agent_router" {
  vm_name          = "CIS274-AgentRouter-FA26"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  iso_interface    = "ide"

  cd_files = [
    "D:/CIS274-Packer/http/agent-router/user-data",
    "D:/CIS274-Packer/http/agent-router/meta-data"
  ]
  cd_label             = "CIDATA"

  cpus                 = 2
  memory               = 2048
  disk_size            = 20480
  guest_os_type        = "Ubuntu_64"
  hard_drive_interface = "sata"
  guest_additions_mode = "disable"

  format           = "ova"
  export_opts      = ["--manifest", "--vsys", "0", "--description", "CIS274 Agent Router FA26", "--version", "1.0"]

  boot_wait = "60s"
  boot_command = [
    "c<wait3>",
    "set gfxpayload=keep<enter><wait2>",
    "linux /casper/vmlinuz boot=casper autoinstall quiet fsck.mode=skip ---<enter><wait5>",
    "initrd /casper/initrd<enter><wait5>",
    "boot<enter>"
  ]

  communicator           = "ssh"
  ssh_username           = "student"
  ssh_password           = "CIS274student!"
  ssh_timeout            = "90m"
  ssh_handshake_attempts = 300
  ssh_wait_timeout       = "90m"

  output_directory = "D:/CIS274-Packer/builds/agent-router-tmp"
  shutdown_command = "echo 'CIS274student!' | sudo -S shutdown -P now"

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--audio", "none"],
    ["modifyvm", "{{.Name}}", "--usb", "off"],
    ["modifyvm", "{{.Name}}", "--vram", "16"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--nic1", "hostonly"],
    ["modifyvm", "{{.Name}}", "--hostonlyadapter1", "VirtualBox Host-Only Ethernet Adapter"],
    ["modifyvm", "{{.Name}}", "--nic2", "nat"]
  ]
}

build {
  name    = "agent-router"
  sources = ["source.virtualbox-iso.agent_router"]

  provisioner "file" {
    source      = "D:/CIS274-Packer/scripts/agent-router/"
    destination = "/tmp/"
  }

  provisioner "shell" {
    execute_command = "echo 'CIS274student!' | sudo -S bash {{.Path}}"
    script          = "D:/CIS274-Packer/scripts/agent-router/provision.sh"
  }

  post-processor "shell-local" {
    inline = [
      "cmd /c move D:\\CIS274-Packer\\builds\\agent-router-tmp\\CIS274-AgentRouter-FA26.ova D:\\CIS274-Packer\\builds\\CIS274-AgentRouter-FA26.ova"
    ]
  }
}