#!/bin/bash
set -e

echo "[INFO] IP değişimi başlatılıyor..."

# Aktif modemleri listele
MODEMS=$(mmcli -L | grep -oE '/Modem/[0-9]+' | awk -F/ '{print $3}')

if [[ -z "$MODEMS" ]]; then
  echo "[HATA] Herhangi bir modem bulunamadı."
  exit 1
fi

for ID in $MODEMS; do
  echo "[INFO] Modem $ID devre dışı bırakılıyor..."
  mmcli -m $ID --disable
  sleep 3

  echo "[INFO] Modem $ID tekrar etkinleştiriliyor..."
  mmcli -m $ID --enable
  sleep 5
done

# IP değiştikten sonra yeniden yönlendirme ve proxy başlatma
echo "[INFO] start.sh yeniden çalıştırılıyor..."
/root/wuwi/start.sh

echo "[OK] IP değiştirildi ve proxy yeniden başlatıldı."
