#!/bin/bash

# Fungsi untuk menginstal Minio
install_minio() {
    echo "Memperbarui sistem..."
    sudo apt update

    # Meminta pengguna untuk memasukkan URL file Minio
    read -p "Masukkan URL file Minio (.deb) yang ingin diunduh: " MINIO_URL

    # Memeriksa apakah URL valid
    if [[ -z "$MINIO_URL" ]]; then
        echo "URL tidak boleh kosong!"
        exit 1
    fi

    echo "Mengunduh Minio dari $MINIO_URL..."
    wget -O minio.deb "$MINIO_URL"
    
    # Memeriksa apakah unduhan berhasil
    if [ $? -ne 0 ]; then
        echo "Gagal mengunduh file Minio!"
        exit 1
    fi

    sudo dpkg -i minio.deb

    echo "Membuat direktori penyimpanan minio..."
    sudo mkdir -p /mnt/minio-storage  # Membuat direktori jika belum ada

    echo "Membuat pengguna minio..."
    sudo useradd -r minio-user -s /sbin/nologin
    sudo chown minio-user:minio-user /mnt/minio-storage

    # Meminta input untuk MINIO_ROOT_USER dan MINIO_ROOT_PASSWORD
    read -p "Masukkan MINIO_ROOT_USER (default: minioadmin): " MINIO_ROOT_USER
    MINIO_ROOT_USER=${MINIO_ROOT_USER:-minioadmin}  # Mengatur default jika kosong

    read -p "Masukkan MINIO_ROOT_PASSWORD (default: miniosecretpassword): " MINIO_ROOT_PASSWORD
    MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-miniosecretpassword}  # Mengatur default jika kosong

    echo "Mengonfigurasi Minio..."
    sudo bash -c "cat > /etc/default/minio <<EOF
MINIO_VOLUMES=\"/mnt/minio-storage\"
MINIO_OPTS=\"--address :9000 --console-address :9001\"
MINIO_ROOT_USER=$MINIO_ROOT_USER
MINIO_ROOT_PASSWORD=$MINIO_ROOT_PASSWORD
EOF"

    echo "Memulai layanan Minio..."
    sudo systemctl daemon-reload
    sudo systemctl start minio
    sudo systemctl enable minio

    echo "Instalasi dan konfigurasi Minio selesai!"
}

# Fungsi untuk menghapus instalasi Minio
uninstall_minio() {
    echo "Menghentikan layanan Minio..."
    sudo systemctl stop minio

    echo "Menghapus paket Minio..."
    sudo dpkg --purge minio

    echo "Menghapus pengguna minio..."
    sudo userdel --force minio-user

    echo "Penghapusan instalasi Minio selesai!"
}

# Logika utama script
if [ "$1" == "install" ]; then
    install_minio
elif [ "$1" == "uninstall" ]; then
    uninstall_minio
else
    echo "Penggunaan: $0 {install|uninstall}"
fi
