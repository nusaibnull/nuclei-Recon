# ReconAuto 🚀

An automated Bash script for streamlined reconnaissance and vulnerability scanning. It integrates Subfinder and Nuclei to find subdomains and scan for vulnerabilities, while sending real-time progress and result notifications directly to your Telegram.

## ✨ Features
* **Automated Tool Installation**: Automatically checks and installs missing dependencies like `Subfinder`, `Nuclei`, and `nuclei-templates` if they are not found in the system.
* **Go PATH Auto-Setup**: Automatically configures the Go environment path (`$HOME/go`) to prevent "command not found" errors during execution.
* **Subdomain Enumeration**: Uses `Subfinder` to silently discover subdomains for a target domain and saves them in an organized output file.
* **Vulnerability Scanning**: Runs `Nuclei` exclusively for `medium`, `high`, and `critical` severity vulnerabilities on the discovered subdomains.
* **Real-time Telegram Notifications**: Sends customized alerts to a specified Telegram chat when the scan starts, when subdomain enumeration finishes (including the count of subdomains found), and when the full scan completes or fails.
* **Color-Coded Output**: Provides clean, color-coded terminal output (Green for success, Yellow for medium severity, Magenta for high severity, and Bold Red for critical alerts) for better readability.

## 🛠️ What will be Installed (If missing)
During the first run, the script will automatically install:
* **Subfinder** (via `go install`).
* **Nuclei** (via `go install`).
* **Nuclei-Templates** (via `git clone` from the ProjectDiscovery repository).

## 📋 Prerequisites
Before running this script, ensure you have the following basic tools installed on your system:
* `Go` (Golang)
* `Git`
* `curl` (used for sending Telegram messages).

## 🚀 Installation & Setup

1. **Clone the repository:**
   ```bash
   git https://github.com/nusaibnull/nuclei-Recon.git
   cd nuclei-Recon
   ```

2. **Configure Telegram Bot:**
   Open the script (`run_nuclei.sh`) in any text editor and replace the placeholder values with your actual Telegram Bot Token and Chat ID:
   ```bash
   TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
   TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"
   ```

3. **Make the script executable:**
   ```bash
   chmod +x run_nuclei.sh
   ```

## 🎯 How to Run
Execute the script from your terminal:
```bash
./run_nuclei.sh
```
When prompted, enter your target domain (e.g., `example.com`). The script will handle the rest, automatically create a `subdomain_list` directory, save the results there as `<target>_subdomain.txt`, and notify you on Telegram throughout the process!

## Run Cloud Shell

<p align="left">
  <a href="https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/nusaibnull/nuclei-Recon.git&tutorial=README.md" target="_blank"><img src="https://gstatic.com/cloudssh/images/open-btn.svg"></a>
</p>

## ⚠️ Disclaimer
This script is intended for educational purposes and authorized security testing only. Do not use this tool against targets you do not have explicit permission to test.
