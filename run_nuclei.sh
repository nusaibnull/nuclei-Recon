#!/bin/bash

# ==========================================
# টেলিগ্রাম বটের তথ্য (এখানে তোমার ডিটেইলস দাও)
# ==========================================
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"

# টেলিগ্রাম মেসেজ পাঠানোর ফাংশন
send_telegram_msg() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" > /dev/null
}

# ==========================================
# ১. কালার ভেরিয়েবল
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
# 0. Go PATH সেটআপ (Command not found ফিক্স)
# ==========================================
# ইউজারের হোম ডিরেক্টরি অনুযায়ী Go-এর পাথ সেট করা হচ্ছে
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

log_success "⚙️ Go PATH সফলভাবে সেট করা হয়েছে!"

# ==========================================
# ২. ইনপুট এবং টুলস চেকআপ
# ==========================================
read -p "Target Domain (e.g. site.com): " target_domain

if [ -z "$target_domain" ]; then
    log_error "❌ ডোমেইন দে! ইনপুট ফাঁকা।"
    exit 1
fi

echo "--------------------------------------------------"
log_high "⚙️ টুলস এবং ডিপেন্ডেন্সি চেক করা হচ্ছে..."

# ১. Nuclei ইন্সটল করা আছে কিনা চেক
if ! command -v nuclei &> /dev/null; then
    log_warning "⚠️ Nuclei পাওয়া যায়নি! Go দিয়ে ইন্সটল করা হচ্ছে..."
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
else
    log_success "✅ Nuclei রেডি আছে।"
fi

# ২. Nuclei-templates ফোল্ডার আছে কিনা চেক
if [ ! -d "nuclei-templates" ]; then
    log_warning "⚠️ Nuclei-templates ফোল্ডার নেই! Github থেকে ক্লোন করা হচ্ছে..."
    git clone https://github.com/projectdiscovery/nuclei-templates.git
else
    log_success "✅ Nuclei-templates রেডি আছে।"
fi

# ৩. Subfinder ইন্সটল করা আছে কিনা চেক
if ! command -v subfinder &> /dev/null; then
    log_warning "⚠️ Subfinder পাওয়া যায়নি! Go দিয়ে ইন্সটল করা হচ্ছে..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
else
    log_success "✅ Subfinder রেডি আছে।"
fi
echo "--------------------------------------------------"

# পাথ এবং ফোল্ডার সেটআপ
base_dir="subdomain_list"
output_file="${base_dir}/${target_domain}_subdomain.txt"
template_path="nuclei-templates"

mkdir -p "$base_dir"

# স্ক্যান শুরুর মেসেজ
send_telegram_msg "🚀 [ReconAuto] $target_domain এর স্ক্যান শুরু হয়েছে..."

# ==========================================
# ৩. STEP 1: SUBFINDER
# ==========================================
log_success "\n🔍 [Step 1] Subfinder দিয়ে সাবডোমেইন বের করা হচ্ছে..."
echo "🎯 Target: $target_domain"
echo "--------------------------------------------------"

./subfinder -d "$target_domain" -nW -o "$output_file" > /dev/null 2>&1

if [ -s "$output_file" ]; then
    subdomain_count=$(wc -l < "$output_file")
    log_success "✅ সাবডোমেইন লিস্ট রেডি: $output_file ($subdomain_count subdomains found)"
    
    # সাবডোমেইন ফাইন্ড শেষ হলে মেসেজ
    send_telegram_msg "✅ Subfinder শেষ! $target_domain এর $subdomain_count টি সাবডোমেইন পাওয়া গেছে।"

    # ==========================================
    # ৪. STEP 2: NUCLEI SCANNING
    # ==========================================
    log_high "\n☢️ [Step 2] Nuclei স্ক্যান শুরু হচ্ছে (High & Critical Only)..."
    echo "--------------------------------------------------"

    # Nuclei রান এবং আউটপুট কালার ফিল্টারিং
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
    log_success "✨ Nuclei স্ক্যান শেষ!"
    
    # স্ক্যান পুরোপুরি শেষ হলে মেসেজ
    send_telegram_msg "✨ [ReconAuto] $target_domain এর Nuclei স্ক্যান সফলভাবে শেষ হয়েছে!"

else
    log_error "\n❌ সমস্যা হয়েছে! Subfinder কোনো সাবডোমেইন খুঁজে পায়নি।"
    send_telegram_msg "❌ [ReconAuto] $target_domain এর Subfinder কোনো সাবডোমেইন পায়নি। স্ক্যান বন্ধ করা হলো।"
fi