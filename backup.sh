#!/usr/bin/env bash
set -Eeuo pipefail
DB_NAME="${DB_NAME:-goldshop}"; BACKUP_ROOT="${BACKUP_ROOT:-/backup/goldshop}"; KEEP_DAYS="${KEEP_DAYS:-7}"
[[ $EUID -eq 0 ]] || { echo 'Run as root.'; exit 1; }
DATE=$(date +%Y%m%d_%H%M%S); WORK="$BACKUP_ROOT/.work_$DATE"; OUT="$BACKUP_ROOT/goldshop_$DATE.tar.gz"
mkdir -p "$WORK" "$BACKUP_ROOT"
sudo -u postgres pg_dump -Fc "$DB_NAME" > "$WORK/goldshop.dump"
cp -a /opt/odoo/custom-addons/gold_shop "$WORK/gold_shop"
cp -a /etc/odoo.conf "$WORK/odoo.conf"
/opt/odoo/venv/bin/pip freeze > "$WORK/python_packages.txt"
/opt/odoo/venv/bin/python /opt/odoo/odoo/odoo-bin --version > "$WORK/odoo_version.txt" 2>&1 || true
DATA_DIR=$(awk -F= '/^[[:space:]]*data_dir[[:space:]]*=/{gsub(/[[:space:]]/,"",$2);print $2}' /etc/odoo.conf | tail -1)
DATA_DIR=${DATA_DIR:-/var/lib/odoo}
[[ -d "$DATA_DIR/filestore/$DB_NAME" ]] && cp -a "$DATA_DIR/filestore/$DB_NAME" "$WORK/filestore" || echo 'WARNING: filestore not found.'
tar -C "$WORK" -czf "$OUT" .
tar -tzf "$OUT" >/dev/null
rm -rf "$WORK"
find "$BACKUP_ROOT" -maxdepth 1 -type f -name 'goldshop_*.tar.gz' -mtime +"$KEEP_DAYS" -delete
echo "Backup OK: $OUT"; ls -lh "$OUT"
