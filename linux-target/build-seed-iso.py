#!/usr/bin/env python3
"""
Build a nocloud seed ISO for Ubuntu 24.04 autoinstall.
Embeds user-data and meta-data so Ubuntu finds ds=nocloud automatically.
"""
import pycdlib
import io
import os

USER_DATA = open(r"D:\CIS274-Packer\http\linux-target\user-data", "rb").read()
META_DATA = open(r"D:\CIS274-Packer\http\linux-target\meta-data", "rb").read()
OUTPUT    = r"D:\CIS274-Packer\iso\linux-target-seed.iso"

os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)

iso = pycdlib.PyCdlib()
iso.new(joliet=3, rock_ridge="1.09", vol_ident="CIDATA")
iso.add_fp(io.BytesIO(USER_DATA), len(USER_DATA),
           "/USER_DATA;1", rr_name="user-data", joliet_path="/user-data")
iso.add_fp(io.BytesIO(META_DATA), len(META_DATA),
           "/META_DATA;1", rr_name="meta-data", joliet_path="/meta-data")
iso.write(OUTPUT)
iso.close()
print(f"[+] Seed ISO written: {OUTPUT} ({os.path.getsize(OUTPUT)} bytes)")
