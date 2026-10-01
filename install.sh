#!/usr/bin/env bash
set -Eeuo pipefail

# Gold Shop Management System - Odoo 19 Community installer
# Supported target: Ubuntu 24.04 LTS, root/sudo execution.
# Override repo before running, e.g.:
#   REPO_URL=https://github.com/USER/gold-shop.git bash install.sh

REPO_URL="${REPO_URL:-https://github.com/YOUR-USERNAME/gold-shop.git}"
BRANCH="${BRANCH:-main}"
ODOO_BRANCH="${ODOO_BRANCH:-19.0}"
DB_NAME="${DB_NAME:-goldshop}"
ODOO_HOME="/opt/odoo"
ODOO_SRC="$ODOO_HOME/odoo"
VENV="$ODOO_HOME/venv"
CUSTOM="$ODOO_HOME/custom-addons"
CONF="/etc/odoo.conf"
SERVICE="/etc/systemd/system/odoo.service"

[[ $EUID -eq 0 ]] || { echo 'Run as root or with sudo.'; exit 1; }
[[ "$REPO_URL" != *YOUR-USERNAME* ]] || { echo 'Set REPO_URL to your GitHub repository first.'; exit 1; }
. /etc/os-release
[[ "${ID:-}" == ubuntu && "${VERSION_ID:-}" == 24.04* ]] || echo 'WARNING: tested for Ubuntu 24.04 LTS.'

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git curl ca-certificates build-essential python3 python3-venv python3-dev \
  libpq-dev libldap2-dev libsasl2-dev libssl-dev libffi-dev libjpeg-dev zlib1g-dev \
  libxml2-dev libxslt1-dev libzip-dev libcairo2 libcairo2-dev pkg-config \
  postgresql postgresql-client nodejs npm

id odoo >/dev/null 2>&1 || useradd --system --home "$ODOO_HOME" --create-home --shell /bin/bash odoo
mkdir -p "$CUSTOM" /var/lib/odoo /var/log/odoo
chown -R odoo:odoo "$ODOO_HOME" /var/lib/odoo /var/log/odoo

if [[ ! -d "$ODOO_SRC/.git" ]]; then
  sudo -u odoo git clone --depth 1 --branch "$ODOO_BRANCH" https://github.com/odoo/odoo.git "$ODOO_SRC"
fi

if [[ ! -d "$VENV" ]]; then sudo -u odoo python3 -m venv "$VENV"; fi
sudo -u odoo "$VENV/bin/pip" install --upgrade pip wheel setuptools
sudo -u odoo "$VENV/bin/pip" install -r "$ODOO_SRC/requirements.txt"
sudo -u odoo "$VENV/bin/pip" install pycairo rlPyCairo

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMP/repo"
rm -rf "$CUSTOM/gold_shop"
cp -a "$TMP/repo/gold_shop" "$CUSTOM/gold_shop"
chown -R odoo:odoo "$CUSTOM/gold_shop"

sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='odoo'" | grep -q 1 || sudo -u postgres createuser odoo
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || sudo -u postgres createdb -O odoo "$DB_NAME"

ADMIN_PASSWD="${ADMIN_PASSWD:-$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(24))
PY
)}"
cat > "$CONF" <<CFG
[options]
admin_passwd = $ADMIN_PASSWD
db_host = False
db_port = False
db_user = odoo
db_password = False
addons_path = $ODOO_SRC/addons,$CUSTOM
data_dir = /var/lib/odoo
logfile = /var/log/odoo/odoo.log
proxy_mode = True
workers = 2
max_cron_threads = 1
limit_memory_soft = 1073741824
limit_memory_hard = 1610612736
CFG
chown odoo:odoo "$CONF"; chmod 640 "$CONF"

cat > "$SERVICE" <<UNIT
[Unit]
Description=Odoo 19 Community
After=network.target postgresql.service
Requires=postgresql.service
[Service]
Type=simple
User=odoo
Group=odoo
ExecStart=$VENV/bin/python $ODOO_SRC/odoo-bin -c $CONF
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl stop odoo 2>/dev/null || true
sudo -u odoo "$VENV/bin/python" "$ODOO_SRC/odoo-bin" -c "$CONF" -d "$DB_NAME" -i gold_shop --without-demo=all --stop-after-init
systemctl enable --now odoo

echo
echo '=================================================='
echo 'Gold Shop installation completed.'
echo "Database: $DB_NAME"
echo 'Odoo: http://SERVER_IP:8069'
echo "Master password: $ADMIN_PASSWD"
echo 'SAVE THE MASTER PASSWORD SECURELY.'
echo '=================================================='
