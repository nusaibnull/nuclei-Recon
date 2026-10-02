#!/bin/bash

# ==========================================
# Telegram Bot Info (Provide your details here)
# ==========================================
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"

# Function to send Telegram messages
send_telegram_msg() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" > /dev/null
}

# ==========================================
# Color Variables
# ==========================================
GREEN='\033[92m'
YELLOW='\033[93m'
MAGENTA='\033[95m'
BOLD_RED='\033[91;1m'
RED='\033[91m'
NC='\033[0m' # No Color

log_success()  { echo -e "${GREEN}$1${NC}"; }
log_warning()  { echo -e "${YELLOW}$1${NC}"; }
log_high()     { echo -e "${MAGENTA}$1${NC}"; }
log_critical() { echo -e "${BOLD_RED}$1${NC}"; }
log_error()    { echo -e "${RED}$1${NC}"; }

# ==========================================
# Go PATH Setup (Fix for 'command not found')
# ==========================================
# Setting Go path based on user's home directory
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

log_success "⚙️ Go PATH successfully configured!"

# ==========================================
# Input and Tools Validation
# ==========================================
read -p "Target Domain (e.g. site.com): " target_domain

if [ -z "$target_domain" ]; then
    log_error "❌ Domain is required! Input cannot be empty."
    exit 1
fi

echo "--------------------------------------------------"
log_high "⚙️ Checking tools and dependencies..."

# Check if Nuclei is installed
if ! command -v nuclei &> /dev/null; then
    log_warning "⚠️ Nuclei not found! Installing via Go..."
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
else
    log_success "✅ Nuclei-templates are ready."
fi

# Check if nuclei-templates folder exists
if [ ! -d "nuclei-templates" ]; then
    log_warning "⚠️️ Nuclei-templates folder missing! Cloning from Github..."
    git clone https://github.com/projectdiscovery/nuclei-templates.git
else
    log_success "✅ Nuclei-templates are ready."
fi

# Check if Subfinder is installed
if ! command -v subfinder &> /dev/null; then
     log_warning "⚠️ Subfinder not found! Installing via Go..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
else
    log_success "✅ Subfinder is ready."
fi
echo "--------------------------------------------------"

# Path and Directory Setup
base_dir="subdomain_list"
output_file="${base_dir}/${target_domain}_subdomain.txt"
template_path="nuclei-templates"

mkdir -p "$base_dir"

# Scan start message
send_telegram_msg "🚀 [ReconAuto] Scan started for $target_domain..."

# ==========================================
# 3. STEP 1: SUBFINDER
# ==========================================
log_success "\n🔍 [Step 1] Enumerating subdomains using Subfinder..."
echo "🎯 Target: $target_domain"
echo "--------------------------------------------------"

./subfinder -d "$target_domain" -nW -o "$output_file" > /dev/null 2>&1

if [ -s "$output_file" ]; then
    subdomain_count=$(wc -l < "$output_file")
    log_success "✅ Subdomain list ready: $output_file ($subdomain_count subdomains found)"
    
    # Message after subdomain enumeration is complete
    send_telegram_msg "✅ Subfinder finished! Found $subdomain_count subdomains for $target_domain."

    # ==========================================
    # STEP 2: NUCLEI SCANNING
    # ==========================================
    log_high "\n☢️ [Step 2] Starting Nuclei scan (High & Critical Only)..."
    echo "--------------------------------------------------"

    # Run Nuclei and filter output with colors
    ./nuclei -list "$output_file" -t "$template_path" -severity medium,high,critical -no-mhe 2>/dev/null | while read -r line; do
        if [[ "$line" == *"[critical]"* ]]; then
            log_critical "🔥 $line"
        elif [[ "$line" == *"[high]"* ]]; then
            log_high "🚨 $line"
        elif [[ "$line" == *"[medium]"* ]]; then
            log_warning "⚠️ $line"
        fi
    done

    echo "--------------------------------------------------"
    log_success "✨ Nuclei scan completed!"
    
    # Message after the full scan is complete
    send_telegram_msg "✨ [ReconAuto] Nuclei scan for $target_domain has finished successfully!"

else
    log_error "\n❌ Error! Subfinder could not find any subdomains."
    send_telegram_msg "❌ [ReconAuto] Subfinder found no subdomains for $target_domain. Scan aborted."
fi