# CareAssets 数据库模式与安全写入规范 (Database Schema & Safety)

CareAssets 采用 SQLite 本地与 iCloud 云盘双库同步机制。本手册记录数据库表结构、字段含义以及安全批量维护流水脚本的规范。

---

## 1. 数据库文件位置与双库同步

CareAssets 维护两份数据库文件，执行任何直接的 SQL 维护或补录时，**必须同时备份并同步写入两处**：

1. **本地数据库 (Local DB)**:
   `~/Library/Application Support/CareAssets/CareAssets.sqlite3`
2. **iCloud 同步数据库 (iCloud Sync DB)**:
   `~/Library/Mobile Documents/com~apple~CloudDocs/CareAsset/CareAssets-sync.sqlite3`
3. **安全备份目录 (Backup Directory)**:
   `~/Library/Application Support/CareAssets/backups/`

> **安全红线**：在执行任何 UPDATE / INSERT / DELETE 之前，必须在 `backups/` 目录下创建带精确时间戳的 `.sqlite3` 完整副本！

---

## 2. 核心表结构：`transactions`

交易流水存储于 `transactions` 表中：

```sql
CREATE TABLE transactions (
    id TEXT PRIMARY KEY NOT NULL,
    occurred_at REAL NOT NULL,
    kind TEXT NOT NULL,
    asset_id TEXT,
    asset_name TEXT NOT NULL DEFAULT '',
    symbol TEXT NOT NULL DEFAULT '',
    asset_type TEXT,
    currency TEXT NOT NULL DEFAULT '',
    quantity REAL NOT NULL DEFAULT 0,
    unit_price REAL NOT NULL DEFAULT 0,
    amount REAL NOT NULL DEFAULT 0,
    fee REAL NOT NULL DEFAULT 0,
    tax REAL NOT NULL DEFAULT 0,
    note TEXT NOT NULL DEFAULT '',
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL,
    account_id TEXT,
    target_account_id TEXT,
    target_currency TEXT NOT NULL DEFAULT '',
    target_amount REAL NOT NULL DEFAULT 0,
    trade_date TEXT NOT NULL DEFAULT '',
    market_time_zone TEXT NOT NULL DEFAULT '',
    executed_at REAL,
    settlement_date TEXT,
    settlement_status TEXT NOT NULL DEFAULT 'notRecorded',
    transaction_levy REAL NOT NULL DEFAULT 0,
    trading_fee REAL NOT NULL DEFAULT 0
);
```

| 字段名 | 类型 | 说明与规范 |
| :--- | :--- | :--- |
| `id` | `TEXT PRIMARY KEY` | 大写 UUID 字符串（如 `88FED80E-1769-4D7F-BA54-4CD9EAB0CA34`） |
| `account_id` | `TEXT` | 关联账户 ID（通常为该券商账户的 UUID，如富途/汇丰账户） |
| `kind` | `TEXT` | 交易类型枚举（小写）：`deposit`, `withdrawal`, `exchange`, `buy`, `sell`, `dividend`, `transfer` |
| `occurred_at` | `REAL` | 发生时间的 UTC 时间戳秒数（Float/Double），通常取当天 12:00:00 UTC |
| `trade_date` | `TEXT` | 交易日期字符串，格式 `YYYY-MM-DD`（如 `2026-05-30`） |
| `symbol` | `TEXT` | 股票/标的代码（如 `TSLA`, `NVDA`, `00700`），出入金或换汇时留空 `""` |
| `asset_name` | `TEXT` | 标的中文/英文名称，出入金或换汇时留空 `""` |
| `currency` | `TEXT` | 基础结算币种（大写三字码：`USD`, `HKD`, `CNY`） |
| `amount` | `REAL` | 变动总金额（正数）。换汇时为**支出金额**；入金时为**入金金额**；买卖时为**成交总额** |
| `unit_price` | `REAL` | 成交单价（非买卖交易填 `0.0`） |
| `quantity` | `REAL` | 成交股数（非买卖交易填 `0.0`） |
| `fee` | `REAL` | 佣金与平台费（非买卖交易填 `0.0`） |
| `tax` | `REAL` | 印花税（Stamp Duty，非买卖交易填 `0.0`） |
| `transaction_levy` | `REAL` | 证监会征费（非买卖交易填 `0.0`） |
| `trading_fee` | `REAL` | 交易所交易费（非买卖交易填 `0.0`） |
| `target_currency` | `TEXT` | 换汇目标币种（如 `USD`），非换汇填 `""` |
| `target_amount` | `REAL` | 换汇目标换得金额（如 `1474.83`），非换汇填 `0.0` |
| `note` | `TEXT` | 交易备注（建议包含银行流水凭证号、转账附言、换汇明细等） |
| `settlement_status` | `TEXT` | 结算状态：`"settled"`, `"unsettled"`, `"notApplicable"` |
| `created_at` | `REAL` | 记录创建时间戳（当前系统 UTC 秒数） |
| `updated_at` | `REAL` | 记录修改时间戳（当前系统 UTC 秒数） |

---

## 3. 快照表：`portfolio_snapshots`

记录每日各市场、各币种的历史资产快照，供折线图绘制：
- `captured_at`: 快照时间戳（秒）
- `market`: 市场枚举（`all`, `us`, `hk`, `cn`）
- `currency`: 币种（`USD`, `HKD`, `CNY`）
- `market_value`: 持仓市值
- `gross_invested`: 累计买入（原总投入）
- `total_pnl`: 累计盈亏
- `net_worth`: 总资产（现金 + 持仓市值）
- `net_deposited`: 净投入本金（累计入金 - 累计出金）

---

## 4. 安全执行脚本模版

在需要通过 Python 脚本维护或导入流水时，应按如下标准流程编写：

```python
import os, shutil, sqlite3, time, uuid, datetime

LOCAL_DB = os.path.expanduser('~/Library/Application Support/CareAssets/CareAssets.sqlite3')
SYNC_DB = os.path.expanduser('~/Library/Mobile Documents/com~apple~CloudDocs/CareAsset/CareAssets-sync.sqlite3')
BACKUP_DIR = os.path.expanduser('~/Library/Application Support/CareAssets/backups')

# 1. 强制备份
os.makedirs(BACKUP_DIR, exist_ok=True)
ts = time.strftime('%Y%m%d_%H%M%S')
shutil.copy2(LOCAL_DB, os.path.join(BACKUP_DIR, f'CareAssets_backup_{ts}.sqlite3'))
if os.path.exists(SYNC_DB):
    shutil.copy2(SYNC_DB, os.path.join(BACKUP_DIR, f'CareAssets_sync_backup_{ts}.sqlite3'))

# 2. 双库同步事务执行
def execute_on_db(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    # 执行 INSERT / UPDATE ...
    conn.commit()
    conn.close()

execute_on_db(LOCAL_DB)
if os.path.exists(SYNC_DB):
    execute_on_db(SYNC_DB)
```
