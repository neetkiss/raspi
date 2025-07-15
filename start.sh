#!/bin/bash
set -e

PROXY_PORT_BASE=10000
PROXY_BIN="/usr/local/bin/3proxy"
PROXY_CFG="/root/wuwi/logs/3proxy.cfg"
LOG_DIR="/root/wuwi/logs"

# Temiz başla
mkdir -p "$LOG_DIR"
echo "" > "$PROXY_CFG"

# Aktif mobil interface'leri bul (wwu* ve usb*)
MOBILE_IFACES=$(ip -br link | awk '{print $1}' | grep -E '^wwu|^usb')

if [[ -z "$MOBILE_IFACES" ]]; then
  echo "[HATA] Mobil çıkış yapılabilecek interface bulunamadı!"
  exit 1
fi

TABLE_ID=100

echo "[INFO] Mobil modemler bulundu: $MOBILE_IFACES"
for IFACE in $MOBILE_IFACES; do
  IP=$(ip -4 addr show dev "$IFACE" | grep inet | awk '{print $2}' | cut -d/ -f1)

  if [[ -z "$IP" ]]; then
    echo "[UYARI] $IFACE arayüzünden IP alınamadı, atlanıyor."
    continue
  fi

  PORT=$((PROXY_PORT_BASE++))
  RT_TABLE="rt_$IFACE"
  echo "$((TABLE_ID++)) $RT_TABLE" >> /etc/iproute2/rt_tables 2>/dev/null || true

  echo "[INFO] $IFACE → $IP port $PORT olarak atanıyor."

  # IP rule + routing
  ip rule add from "$IP" table "$RT_TABLE" priority 1000
  ip route add default dev "$IFACE" table "$RT_TABLE"

  # 3proxy konfigürasyon satırı ekle
  echo "proxy -n -a -p$PORT -i0.0.0.0 -e$IP" >> "$PROXY_CFG"
done

# 3proxy başlat
pkill 3proxy || true
$PROXY_BIN "$PROXY_CFG" &
echo "[OK] 3proxy başlatıldı: $(pgrep -fl 3proxy)"

# UFW üzerinden ETH/WLAN çıkışı engelle
ufw route delete allow out on eth0 to any port 80 proto tcp || true
ufw route delete allow out on wlan0 to any port 80 proto tcp || true

ufw route allow out on wwu+ to any port 80 proto tcp
ufw route deny out on eth0 to any port 80 proto tcp
ufw route deny out on wlan0 to any port 80 proto tcp

ufw reload

echo "[OK] Script tamamlandı. Proxy'ler mobil hat üzerinden çıkıyor."
