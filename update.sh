#!/bin/bash

# --- Variabel Warna ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 'set -e' akan membuat skrip berhenti jika ada perintah yang gagal
set -e

# --- Fungsi ---

# Fungsi untuk memeriksa apakah perintah yang dibutuhkan ada
check_dependencies() {
    local deps=("wget" "unzip" "lolcat" "tput")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Error: Perintah '$cmd' tidak ditemukan. Silakan install terlebih dahulu.${NC}"
            exit 1
        fi
    done
}

# Fungsi untuk menampilkan progress bar saat sebuah perintah dijalankan
show_progress_bar() {
    local command_to_run="$1"
    local message="$2"
    local marker_file="$HOME/.progress_marker"

    # Jalankan perintah di background
    (
        rm -f "$marker_file"
        # Jalankan perintah dan pastikan tidak ada output yang mengganggu
        eval "$command_to_run" >/dev/null 2>&1
        touch "$marker_file"
    ) &

    # Tampilkan animasi loading
    tput civis # Sembunyikan kursor
    echo -ne "  ${YELLOW}${message} - [${NC}"
    while true; do
        if [[ -f "$marker_file" ]]; then
            rm -f "$marker_file"
            printf '%0.s#' {1..18} # Pastikan bar terisi penuh
            break
        fi
        echo -ne "${GREEN}#${NC}"
        sleep 0.1
    done
    echo -e "${YELLOW}] - ${GREEN}OK !${NC}"
    tput cnorm # Tampilkan kursor kembali
}

# Fungsi utama untuk melakukan proses update
perform_update() {
    # 1. Unduh dan ekstrak file menu
    wget -q https://raw.githubusercontent.com/acilshops/acil/main/menu/menu.zip -O menu.zip
    unzip -o menu.zip -d /usr/local/sbin/
    chmod +x /usr/local/sbin/*

    # 2. Unduh dan jalankan skrip fv-tunnel
    wget -qO /usr/local/sbin/fv-tunnel "https://raw.githubusercontent.com/acilshops/acil/main/config/fv-tunnel"
    chmod +x /usr/local/sbin/fv-tunnel
    /usr/local/sbin/fv-tunnel

    # 3. Bersihkan file sementara
    rm -f menu.zip
    rm -f /usr/local/sbin/fv-tunnel
    # PERINTAH PENGHAPUSAN DIRI DIHAPUS DARI SINI
    # rm -f "$0" 
}

# --- Eksekusi Utama ---

main() {
    clear
    
    # 1. Periksa hak akses root
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "${RED}Error: Skrip ini harus dijalankan sebagai root.${NC}"
        exit 1
    fi

    # 2. Periksa dependensi
    check_dependencies

    # 3. Tampilkan header
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | lolcat
    echo -e " \e[1;97;101m            UPDATE SCRIPT               \e[0m"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | lolcat
    echo ""

    # 4. Muat ulang aturan firewall
    show_progress_bar "systemctl restart netfilter-persistent" "Reloading Firewall Rules"
    
    # 5. Jalankan proses update dengan progress bar
    show_progress_bar "perform_update" "Updating Script Service"

    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | lolcat
    echo -e "\n${GREEN}Skrip berhasil diperbarui!${NC}"
    echo ""
    read -n 1 -s -r -p "Tekan [ Enter ] untuk kembali ke menu..."

    # PERINTAH PENGHAPUSAN DIRI DIPINDAHKAN KE SINI
    # Dijalankan di background dengan jeda 1 detik untuk memberi waktu skrip ini keluar
    (sleep 1 && rm -f "$0") &
    
    # Jalankan menu baru
    menu
}

# Panggil fungsi utama
main