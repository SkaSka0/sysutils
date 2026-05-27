#!/bin/bash

# Daftar package bloatware yang AMAN untuk di-uninstall berdasarkan list HP kamu
BLOATWARE=(
    "com.facebook.appmanager"
    "com.facebook.services"
    "com.facebook.system"
    "com.miui.analytics"
    "com.miui.bugreport"
    "com.miui.fm"
    "com.miui.fmservice"
    "com.miui.miservice"
    "com.miui.misightservice"
    "com.miui.msa.global"
    "com.miui.phrase"
    "com.miui.player"
    "com.miui.videoplayer"
    "com.miui.yellowpage"
    "com.mi.appfinder"
    "com.mi.globalbrowser"
    "com.mi.globalminusscreen"
    "com.miui.cleaner"
    "com.miui.daemon"
    "com.miui.qr"
    "com.miui.thirdappassistant"
    "com.xiaomi.glgm"
    "com.xiaomi.mipicks"
    "com.xiaomi.payment"
    "org.mipay.android.manager"
    "com.microsoftsdk.crossdeviceservicebroker"
)

echo "=== Memulai Proses Debloat via ADB ==="
echo "Pastikan HP sudah terhubung (cek via 'adb devices')"
echo "------------------------------------------------"

# Cek apakah ada perangkat yang terhubung
if ! adb devices | grep -q -w "device"; then
    echo "❌ Error: Perangkat tidak terdeteksi! Jalankan 'adb connect' terlebih dahulu."
    exit 1
fi

# Looping untuk uninstall setiap package
for app in "${BLOATWARE[@]}"; do
    echo -n "Memproses $app... "
    # Jalankan perintah adb dan sembunyikan error jika app memang sudah terhapus
    output=$(adb shell pm uninstall --user 0 "$app" 2>&1)
    
    if [[ "$output" == *"Success"* ]]; then
        echo "✅ BERHASIL"
    elif [[ "$output" == *"not installed"* ]]; then
        echo "⏭️  LEWAT (Sudah tidak ada)"
    else
        echo "❌ GAGAL ($output)"
    fi
done

echo "------------------------------------------------"
echo "🎉 Proses Debloat Selesai!"
echo "Silakan ketik 'adb reboot' untuk merestart HP kamu."
