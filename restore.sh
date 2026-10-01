#!/usr/bin/env bash
set -Eeuo pipefail
ARCHIVE="${1:-}"; DB_NAME="${DB_NAME:-goldshop}"
[[ $EUID -eq 0 ]] || { echo 'Run as root.'; exit 1; }
[[ -f "$ARCHIVE" ]] || { echo 'Usage: sudo ./restore.sh /path/to/goldshop_backup.tar.gz'; exit 1; }
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
tar -xzf "$ARCHIVE" -C "$TMP"
DUMP=$(find "$TMP" -name goldshop.dump -type f | head -1); [[ -n "$DUMP" ]] || { echo 'goldshop.dump missing'; exit 1; }
MODULE=$(find "$TMP" -type d -name gold_shop | head -1)
FILESTORE=$(find "$TMP" -type d -name filestore | head -1)
systemctl stop odoo 2>/dev/null || true
sudo -u postgres dropdb --if-exists "$DB_NAME"
sudo -u postgres createdb -O odoo "$DB_NAME"
sudo -u postgres pg_restore --no-owner --role=odoo -d "$DB_NAME" "$DUMP"
if [[ -n "$MODULE" ]]; then rm -rf /opt/odoo/custom-addons/gold_shop; cp -a "$MODULE" /opt/odoo/custom-addons/gold_shop; chown -R odoo:odoo /opt/odoo/custom-addons/gold_shop; fi
DATA_DIR=$(awk -F= '/^[[:space:]]*data_dir[[:space:]]*=/{gsub(/[[:space:]]/,"",$2);print $2}' /etc/odoo.conf | tail -1); DATA_DIR=${DATA_DIR:-/var/lib/odoo}
if [[ -n "$FILESTORE" ]]; then rm -rf "$DATA_DIR/filestore/$DB_NAME"; mkdir -p "$DATA_DIR/filestore"; cp -a "$FILESTORE" "$DATA_DIR/filestore/$DB_NAME"; chown -R odoo:odoo "$DATA_DIR/filestore/$DB_NAME"; fi
systemctl start odoo
echo 'Restore completed. Verify login, records, images, barcode and finance before production use.'
