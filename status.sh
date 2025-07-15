#!/bin/bash
set -e

echo "📡 Aktif Mobil Arayüzler ve IP'ler:"
echo "-----------------------------------"

MOBILE_IFACES=$(ip -br link | awk '{print $1}' | grep -E '^wwu|^usb')

for IFACE in $MOBILE_IFACES; do
  IP=$(ip -4 addr show dev "$IFACE" | grep inet | awk '{print $2}' | cut -d/ -f1)
  echo "➡️  $IFACE → $IP"
done

echo ""
echo "🧩 Aktif 3proxy Konfigürasyonu:"
echo "-------------------------------"

CFG="/root/wuwi/logs/3proxy.cfg"
if [[ -f "$CFG" ]]; then
  grep "^proxy" "$CFG"
else
  echo "⚠️  3proxy yapılandırması bulunamadı."
fi

echo ""
echo "🚦 Aktif 3proxy Süreci:"
echo "------------------------"
ps -ef | grep '[3]proxy' || echo "❌ 3proxy çalışmıyor."
