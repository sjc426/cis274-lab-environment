#!/bin/bash
# =============================================================
# CIS274-AgentRouter-FA26 -- Provision Script
# Flask C2 server + agent queue for multi-agent lab exercises
# =============================================================
set -e
export DEBIAN_FRONTEND=noninteractive

echo "[*] Updating system..."
apt-get update -y
apt-get upgrade -y

apt-get install -y python3 python3-pip python3-venv git curl wget

# ---- Flask C2 setup ----------------------------------------
echo "[*] Setting up Flask C2 agent router..."
mkdir -p /opt/c2-router
cd /opt/c2-router

python3 -m venv venv
source venv/bin/activate
pip install flask flask-cors requests

# C2 server app
cat > /opt/c2-router/app.py << 'PYEOF'
#!/usr/bin/env python3
"""
CIS274 Agent Router -- Flask C2
Manages task queue for multi-agent lab exercises
"""
from flask import Flask, jsonify, request
import json, os, datetime

app = Flask(__name__)
TASK_FILE = "/opt/c2-router/tasks.json"
RESULT_FILE = "/opt/c2-router/results.json"

def load_json(path):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return []

def save_json(path, data):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)

@app.route('/')
def index():
    return jsonify({"status": "CIS274 Agent Router running", "time": str(datetime.datetime.now())})

@app.route('/tasks', methods=['GET'])
def get_tasks():
    return jsonify(load_json(TASK_FILE))

@app.route('/tasks', methods=['POST'])
def add_task():
    tasks = load_json(TASK_FILE)
    task = request.json
    task['id'] = len(tasks) + 1
    task['created'] = str(datetime.datetime.now())
    task['status'] = 'pending'
    tasks.append(task)
    save_json(TASK_FILE, tasks)
    return jsonify(task), 201

@app.route('/tasks/<int:task_id>/claim', methods=['POST'])
def claim_task(task_id):
    tasks = load_json(TASK_FILE)
    for t in tasks:
        if t['id'] == task_id and t['status'] == 'pending':
            t['status'] = 'claimed'
            t['agent'] = request.json.get('agent', 'unknown')
            save_json(TASK_FILE, tasks)
            return jsonify(t)
    return jsonify({"error": "task not found or already claimed"}), 404

@app.route('/results', methods=['POST'])
def post_result():
    results = load_json(RESULT_FILE)
    result = request.json
    result['received'] = str(datetime.datetime.now())
    results.append(result)
    save_json(RESULT_FILE, results)
    return jsonify(result), 201

@app.route('/results', methods=['GET'])
def get_results():
    return jsonify(load_json(RESULT_FILE))

@app.route('/reset', methods=['POST'])
def reset():
    save_json(TASK_FILE, [])
    save_json(RESULT_FILE, [])
    return jsonify({"status": "reset complete"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
PYEOF

chown -R student:student /opt/c2-router

# ---- Systemd service ----------------------------------------
cat > /etc/systemd/system/c2-router.service << 'SVCEOF'
[Unit]
Description=CIS274 Agent Router (Flask C2)
After=network.target

[Service]
User=student
WorkingDirectory=/opt/c2-router
ExecStart=/opt/c2-router/venv/bin/python app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable c2-router
systemctl start c2-router

# ---- Static IP via netplan ----------------------------------
cat > /etc/netplan/01-cis274.yaml << 'NETPLAN'
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [192.168.56.30/24]
    enp0s8:
      dhcp4: yes
NETPLAN
netplan apply || true

# ---- MOTD ---------------------------------------------------
cat > /etc/motd << 'MOTD'
  CIS274 Agent Router -- Fall 2026
  IP: 192.168.56.30   Flask C2: http://192.168.56.30:5000
  User: student   Pass: CIS274student!
MOTD

# ---- Cleanup -----------------------------------------------
apt-get autoremove -y
apt-get clean
rm -rf /tmp/*
history -c
echo "[+] Agent Router provisioning complete!"
