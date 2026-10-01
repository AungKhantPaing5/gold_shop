# Gold Shop Management System

Custom Gold Shop Management System for **Odoo 19 Community Edition**.

## One-line install

After replacing `YOUR-USERNAME` with the GitHub account that owns this repository:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/gold-shop/main/install.sh | sudo env REPO_URL=https://github.com/YOUR-USERNAME/gold-shop.git bash
```

Target: **Ubuntu 24.04 LTS**. Default database: `goldshop`.

> The installer creates a fresh database. It does **not** restore customer production data. Database and filestore backups must remain outside GitHub.

## Update

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USERNAME/gold-shop/main/update.sh | sudo env REPO_URL=https://github.com/YOUR-USERNAME/gold-shop.git bash
```

`update.sh` creates an application backup before replacing the module and upgrading `gold_shop`.

## Backup

```bash
sudo ./backup.sh
```

Default backup directory: `/backup/goldshop`. It includes PostgreSQL, filestore, custom module, Odoo config, Odoo version and Python package list. Default local retention is 7 days.

## Restore

Install the compatible Odoo 19 environment first, then:

```bash
sudo ./restore.sh /path/to/goldshop_YYYYMMDD_HHMMSS.tar.gz
```

Always verify transactions, jewellery images, stock, barcode reports and finance after restoring.

## Features

Jewellery inventory; Kyat/Pae/Yway/Gram conversion; purity and price management; old-gold purchase; new-gold/jewellery sales; exchange; barcode label and item scanner; customer voucher; stock ledger; opening stock; income/expense finance; automatic transaction-to-finance integration; backend UI styling.

## Production notes

- Keep customer database dumps, filestore and secrets **out of GitHub**.
- Use HTTPS and firewall PostgreSQL from the public Internet.
- Keep an off-site backup in addition to VPS/provider backups.
- Test restore procedures periodically.
- Review Odoo and module security permissions before customer go-live.

## Current known development items

Finance dashboard enhancements, Excel export, dedicated Gold Shop security group/final permission audit, and production off-site backup automation still require final implementation/testing.
