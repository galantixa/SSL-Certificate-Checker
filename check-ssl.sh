#!/bin/bash

# File yang berisi daftar domain
DOMAIN_FILE="/path/to/your/.env"

# Token Bot Telegram dan ID Chat
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
MESSAGE_THREAD_ID=""

# URL API Telegram
TELEGRAM_API_URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"

# Fungsi untuk mengirim pesan ke Telegram
send_telegram_message() {
    local message=$1
    curl -X POST -H 'Content-Type: application/json' \
        -d "{\"message_thread_id\": \"$MESSAGE_THREAD_ID\", \"chat_id\": \"$TELEGRAM_CHAT_ID\", \"text\": \"$message\"}" \
        $TELEGRAM_API_URL
}

# Fungsi untuk memeriksa tanggal kedaluwarsa SSL
check_ssl_expiration() {
    local domain=$1
    # echo "Memeriksa domain: $domain" # Commented out to avoid terminal output

    # Mengambil tanggal kedaluwarsa dari sertifikat SSL
    expiration_date=$(echo | openssl s_client -connect "$domain":443 2>/dev/null \
        | openssl x509 -noout -dates \
        | grep 'notAfter=' \
        | sed 's/notAfter=//')

    if [ -z "$expiration_date" ]; then
        local message="⭕️ Tidak dapat mengambil tanggal kedaluwarsa untuk $domain"
        # echo "$message" # Commented out to avoid terminal output
        send_telegram_message "$message"
        return
    fi

    # Mengonversi tanggal kedaluwarsa ke format Unix timestamp
    expiration_timestamp=$(date -d "$expiration_date" +%s)
    current_timestamp=$(date +%s)
    days_left=$(( (expiration_timestamp - current_timestamp) / 86400 ))

    if [ "$days_left" -lt 0 ]; then
        local message="❌ Sertifikat untuk $domain telah kedaluwarsa sejak $((-days_left)) hari yang lalu"
    elif [ "$days_left" -le 30 ]; then
        local message="🔴 Sertifikat untuk $domain akan kedaluwarsa dalam waktu $days_left hari (hingga $expiration_date). @galantixa Info IMP & PIC terkait"
    #else
        local message="🟢 Sertifikat untuk $domain berlaku selama $days_left hari lagi (hingga $expiration_date)"
    fi

    # echo "$message" # Commented out to avoid terminal output
    send_telegram_message "$message"
}

# Membaca daftar domain dari file dan memeriksa setiap domain
while IFS= read -r domain; do
    if [ -n "$domain" ]; then
        check_ssl_expiration "$domain"
    fi
done < "$DOMAIN_FILE"
