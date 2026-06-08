packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}
variable "iso_url" {
  default = "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso"
}
variable "iso_checksum" {
  default = "sha256:e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433"
}
source "virtualbox-iso" "linux_target" {
  vm_name          = "CIS274-Linux-Target-FA26"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  iso_interface    = "ide"
  cd_files = [
    "D:/CIS274-Packer/http/linux-target/user-data",
    "D:/CIS274-Packer/http/linux-target/meta-data"
  ]
  cd_label             = "CIDATA"
  cpus                 = 2
  memory               = 2048
  disk_size            = 40960
  guest_os_type        = "Ubuntu_64"
  hard_drive_interface = "sata"
  guest_additions_mode = "disable"
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
  output_directory = "D:/CIS274-Packer/builds/linux-target-tmp"
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
  name    = "linux-target"
  sources = ["source.virtualbox-iso.linux_target"]
  provisioner "file" {
    source      = "D:/CIS274-Packer/scripts/linux-target/"
    destination = "/tmp/"
  }
  provisioner "shell" {
    execute_command = "echo 'CIS274student!' | sudo -S bash {{.Path}}"
    script          = "D:/CIS274-Packer/scripts/linux-target/provision.sh"
  }
  post-processor "shell-local" {
    inline = [
      "VBoxManage export CIS274-Linux-Target-FA26 --output D:/CIS274-Packer/builds/CIS274-Linux-Target-FA26.ova --ovf20 --manifest"
    ]
  }
}
