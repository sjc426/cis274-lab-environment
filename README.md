# CIS 274 — Ethical Hacking & Pen Testing
## Lab Environment Build System
**Community College of Philadelphia | Fall 2026**

This repo contains all HashiCorp Packer configs to rebuild the CIS 274 lab VMs from scratch.
One command per VM. Fully reproducible. Zero manual steps.

---

## VM Inventory

| OVA | Description | Size | Network IP |
|-----|-------------|------|------------|
| `CIS274-Kali-FA26.ova` | Attacker VM — Kali + Ollama/Mistral | ~20 GB | 192.168.56.10 |
| `CIS274-Linux-Target-FA26.ova` | Linux Target — Ubuntu + DVWA + vsftpd | ~3.4 GB | 192.168.56.20 |
| `CIS274-Windows-Target-FA26.ova` | Windows Target — Server 2019 + SMBv1 | ~5.2 GB | 192.168.56.30 |
| `CIS274-AgentRouter-FA26.ova` | Agent Router — Ubuntu + Flask C2 | ~2 GB | 192.168.56.40 |

> **OVA files are NOT stored here** (too large for GitHub).
> Student download link: OneDrive (see Canvas → Start Here module)

---

## Repo Structure

```
cis274-lab-environment/
  kali/                    # Kali attacker build
    kali.pkr.hcl
  linux-target/            # Ubuntu target build
    linux-target.pkr.hcl
    build-seed-iso.py
  windows-target/          # Windows Server 2019 target build
    windows-target.pkr.hcl
  agent-router/            # Agent router build
    agent-router.pkr.hcl
  scripts/                 # Provisioner scripts (run inside VMs)
    kali/provision.sh
    linux-target/provision.sh
    agent-router/provision.sh
    windows-target/provision.ps1
    windows-target/winrm-setup.ps1
  http/                    # Autoinstall / preseed configs (served via HTTP)
    kali/preseed.cfg
    linux-target/user-data
    linux-target/meta-data
    agent-router/user-data
    agent-router/meta-data
    windows-target/Autounattend.xml
```

---

## Prerequisites

- Windows machine with VirtualBox 7.2+ installed
- HashiCorp Packer installed (`winget install HashiCorp.Packer`)
- D: drive with ~60 GB free for builds
- Windows Server 2019 Eval ISO in `D:\CIS274-Packer\iso\`

---

## Build Order

Always build in this order (dependencies):

```powershell
# 1. Linux Target (~25 min)
cd linux-target
packer build linux-target.pkr.hcl

# 2. Windows Target (~50 min)
cd ..\windows-target
packer build windows-target.pkr.hcl

# 3. Agent Router (~25 min)
cd ..\agent-router
packer build agent-router.pkr.hcl

# 4. Kali Full — build last, longest (~90 min)
cd ..\kali
packer build kali.pkr.hcl
```

---

## Key Lessons Learned (FA26 Build)

1. **NAT NIC must be nic1** — Packer hardcodes `natpf1` for WinRM. nic1=NAT, nic2=host-only.
2. **OVA export** — Use `format=ova` in source block, not shell-local post-processor (VM is unregistered before shell-local runs).
3. **Static IP on Windows** — Never target the first adapter blindly. Exclude NAT range (10.0.2.*) to find the host-only adapter.
4. **ASCII only in PS scripts** — Em-dash / en-dash characters cause WinRM parse errors. Keep provision scripts pure ASCII.
5. **packer_cache folders** — Never commit these (see .gitignore). They contain multi-GB ISO caches.

---

## Student Distribution

OVAs are distributed via OneDrive public link posted in Canvas.
Never host OVA files on GitHub — file size limit is 100 MB.

---

*Built by Prof. Sonny Chang — CCP CIS Department*