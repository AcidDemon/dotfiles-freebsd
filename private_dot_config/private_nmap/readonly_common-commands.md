# Nmap Common Commands Cheatsheet

## Host Discovery
- `nmap -sn <network>` - Ping scan (no port scan)
- `nmap -Pn <host>` - Skip host discovery (treat as online)

## Port Scanning
- `nmap -p- <host>` - Scan all 65535 ports
- `nmap -p 22,80,443 <host>` - Scan specific ports
- `nmap --top-ports 20 <host>` - Scan top 20 ports

## Service/Version Detection
- `nmap -sV <host>` - Probe open ports for service/version
- `nmap -A <host>` - Aggressive scan (OS, version, scripts, traceroute)

## NSE Scripts
- `nmap --script <script> <host>` - Run specific script
- `nmap --script-help <script>` - Get help for script
- `nmap --script vuln <host>` - Run vulnerability scripts

## Timing Templates (-T)
- `-T0` - Paranoid (slowest, IDS evasion)
- `-T1` - Sneaky
- `-T2` - Polite
- `-T3` - Normal (default)
- `-T4` - Aggressive (faster, recommended for local networks)
- `-T5` - Insane (fastest, may miss results)

## Output Formats
- `-oN <file>` - Normal output
- `-oX <file>` - XML output
- `-oG <file>` - Grepable output
- `-oA <basename>` - All formats at once

## Useful Script Categories
- `auth` - Authentication bypass/brute force
- `broadcast` - Network broadcast discovery
- `brute` - Brute force attacks
- `discovery` - Service discovery
- `dos` - Denial of service (be careful!)
- `exploit` - Exploit known vulnerabilities
- `intrusive` - May crash target or use lots of resources
- `malware` - Check for backdoors/malware
- `safe` - Won't affect target
- `version` - Version detection enhancement
- `vuln` - Vulnerability detection
