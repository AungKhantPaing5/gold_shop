#!/usr/bin/env bash
set -Eeuo pipefail
REPO_URL="${REPO_URL:-https://github.com/YOUR-USERNAME/gold-shop.git}"
BRANCH="${BRANCH:-main}"; DB_NAME="${DB_NAME:-goldshop}"
[[ $EUID -eq 0 ]] || { echo 'Run as root.'; exit 1; }
[[ "$REPO_URL" != *YOUR-USERNAME* ]] || { echo 'Set REPO_URL first.'; exit 1; }
# Backup before changing code.
SCRIPT_DIR=$(mktemp -d); trap 'rm -rf "$SCRIPT_DIR"' EXIT
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$SCRIPT_DIR/repo"
bash "$SCRIPT_DIR/repo/backup.sh"
systemctl stop odoo
rm -rf /opt/odoo/custom-addons/gold_shop
cp -a "$SCRIPT_DIR/repo/gold_shop" /opt/odoo/custom-addons/gold_shop
chown -R odoo:odoo /opt/odoo/custom-addons/gold_shop
sudo -u odoo /opt/odoo/venv/bin/python /opt/odoo/odoo/odoo-bin -c /etc/odoo.conf -d "$DB_NAME" -u gold_shop --stop-after-init --logfile=/dev/stdout
systemctl start odoo
systemctl --no-pager --full status odoo | head -20
