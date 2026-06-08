#!/bin/bash
# =============================================================
# CIS274-Kali-FA26 — Provision Script
# Installs: kali tools, Metasploit, Ollama + mistral:7b
# =============================================================
set -e
export DEBIAN_FRONTEND=noninteractive

echo "[*] Updating Kali..."
apt-get update -y
apt-get upgrade -y

# ---- Core security tools ------------------------------------
echo "[*] Installing kali-linux-top10 tools..."
apt-get install -y \
    kali-tools-top10 \
    metasploit-framework \
    nmap \
    wireshark \
    burpsuite \
    gobuster \
    hydra \
    john \
    hashcat \
    sqlmap \
    nikto \
    netcat-openbsd \
    python3 python3-pip python3-venv \
    git curl wget vim tmux

# ---- Metasploit DB setup ------------------------------------
echo "[*] Initializing Metasploit database..."
systemctl enable postgresql
systemctl start postgresql
msfdb init || true

# ---- Static IP 192.168.56.100 ------------------------------
echo "[*] Configuring static IP..."
cat > /etc/network/interfaces.d/eth0 << 'IFACE'
auto eth0
iface eth0 inet static
  address 192.168.56.100
  netmask 255.255.255.0
IFACE

# ---- Ollama install ----------------------------------------
echo "[*] Installing Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# ---- Systemd for Ollama ------------------------------------
systemctl enable ollama
systemctl start ollama

# Wait for Ollama to be ready
echo "[*] Waiting for Ollama daemon..."
sleep 10
for i in $(seq 1 30); do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "[*] Ollama ready."
        break
    fi
    sleep 5
done

# ---- Pull mistral:7b (5GB — bake into OVA disk) ------------
echo "[*] Pulling mistral:7b — this takes 10-20 min..."
ollama pull mistral:7b

echo "[*] Verifying mistral pull..."
ollama list

# ---- Lab aliases + student config --------------------------
cat >> /home/student/.bashrc << 'ALIASES'

# === CIS274 Lab Aliases ===
alias target-linux='ssh student@192.168.56.10'
alias target-win='xfreerdp /u:student /p:CIS274student! /v:192.168.56.20 /cert-ignore &'
alias c2='curl -s http://192.168.56.30:5000'
alias ai='ollama run mistral'
alias msfup='sudo systemctl start postgresql && sudo msfdb init && msfconsole'
export OLLAMA_HOST=localhost:11434
ALIASES

chown student:student /home/student/.bashrc

# ---- Lab banner --------------------------------------------
cat > /etc/motd << 'MOTD'
 ██████╗ ██╗███████╗    ██████╗ ███████╗ ██╗  ██╗
██╔════╝ ██║██╔════╝    ╚════██╗╚════██║ ██║  ██║
██║      ██║███████╗     █████╔╝    ██╔╝ ███████║
██║      ██║╚════██║    ██╔═══╝    ██╔╝  ╚════██║
╚██████╗ ██║███████║    ███████╗   ██║        ██║
 ╚═════╝ ╚═╝╚══════╝    ╚══════╝   ╚═╝        ╚═╝

  Kali Attacker VM — CIS 274 Fall 2026
  IP: 192.168.56.100   User: student   Pass: CIS274student!
  AI:      ollama run mistral  (or: ai)
  Targets: 192.168.56.10 (Linux)  192.168.56.20 (Windows)
  C2:      http://192.168.56.30:5000
MOTD

# ---- Cleanup -----------------------------------------------
echo "[*] Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /tmp/*
history -c
echo "[+] Kali provisioning complete!"