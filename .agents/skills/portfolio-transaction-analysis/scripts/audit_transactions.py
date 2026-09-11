#!/usr/bin/env python3
"""
CareAssets 交易流水与本金审计脚本
用于审计本地与 iCloud 同步数据库中的交易记录，核对入金、换汇、买卖总额及数据一致性。
"""

import os
import sqlite3
import sys

LOCAL_DB = os.path.expanduser('~/Library/Application Support/CareAssets/CareAssets.sqlite3')
SYNC_DB = os.path.expanduser('~/Library/Mobile Documents/com~apple~CloudDocs/CareAsset/CareAssets-sync.sqlite3')

def format_curr(amount, currency):
    return f"{amount:,.2f} {currency}"

def audit_database(db_path, label="Database"):
    if not os.path.exists(db_path):
        print(f"[{label}] 数据库文件不存在: {db_path}")
        return None

    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
    except sqlite3.OperationalError as e:
        print(f"[{label}] 无法打开数据库 ({e})，可能由于沙盒权限限制或文件锁定。")
        return None

    print(f"\n==================================================")
    print(f" 审计报告: {label}")
    print(f" 路径: {db_path}")
    print(f"==================================================")

    # 1. 统计各类型记录条数
    cur.execute("SELECT kind, count(*) FROM transactions GROUP BY kind")
    kinds_count = dict(cur.fetchall())
    total_tx = sum(kinds_count.values())
    print(f"\n[1] 交易记录总数: {total_tx} 条")
    for kind, cnt in sorted(kinds_count.items()):
        print(f"  - {kind:<12}: {cnt} 笔")

    # 2. 外部入金与出金（净投入本金）
    print(f"\n[2] 资金存取（外部本金）统计:")
    cur.execute("""
        SELECT currency,
               SUM(CASE WHEN kind = 'deposit' THEN amount ELSE 0 END) as deposits,
               SUM(CASE WHEN kind = 'withdrawal' THEN amount ELSE 0 END) as withdrawals
        FROM transactions
        WHERE kind IN ('deposit', 'withdrawal')
        GROUP BY currency
    """)
    funding_rows = cur.fetchall()
    if not funding_rows:
        print("  (暂无出入金记录)")
    for curr, dep, withdr in funding_rows:
        net = dep - withdr
        print(f"  * {curr}:")
        print(f"      累计入金: {format_curr(dep, curr)}")
        print(f"      累计出金: {format_curr(withdr, curr)}")
        print(f"      净投入额: {format_curr(net, curr)}")

    # 3. 换汇记录统计
    print(f"\n[3] 货币兑换 (FX Exchange) 统计:")
    cur.execute("""
        SELECT currency, target_currency, SUM(amount), SUM(target_amount), count(*)
        FROM transactions
        WHERE kind = 'exchange'
        GROUP BY currency, target_currency
    """)
    fx_rows = cur.fetchall()
    if not fx_rows:
        print("  (暂无换汇记录)")
    for from_c, to_c, from_a, to_a, cnt in fx_rows:
        rate = to_a / from_a if from_a > 0 else 0
        print(f"  * {from_c} -> {to_c}: {cnt} 笔 | 支出: {format_curr(from_a, from_c)} -> 换得: {format_curr(to_a, to_c)} (平均汇率: {rate:.4f})")

    # 4. 股票买卖与累计买入
    print(f"\n[4] 证券交易统计:")
    cur.execute("""
        SELECT currency,
               SUM(CASE WHEN kind = 'buy' THEN amount + fee + tax + transaction_levy + trading_fee ELSE 0 END) as buy_total,
               SUM(CASE WHEN kind = 'sell' THEN amount ELSE 0 END) as sell_total,
               SUM(fee + tax + transaction_levy + trading_fee) as total_fees,
               count(*)
        FROM transactions
        WHERE kind IN ('buy', 'sell')
        GROUP BY currency
    """)
    trade_rows = cur.fetchall()
    if not trade_rows:
        print("  (暂无股票交易记录)")
    for curr, buy_tot, sell_tot, fees, cnt in trade_rows:
        print(f"  * {curr}:")
        print(f"      累计买入 (Gross Invested): {format_curr(buy_tot, curr)}")
        print(f"      累计卖出回笼资金:       {format_curr(sell_tot, curr)}")
        print(f"      累计交易费用:           {format_curr(fees, curr)}")

    # 5. 异常校验
    print(f"\n[5] 异常检测:")
    anomalies = []
    # 检查换汇无目标币种
    cur.execute("SELECT count(*) FROM transactions WHERE kind = 'exchange' AND (target_currency = '' OR target_amount <= 0)")
    bad_fx = cur.fetchone()[0]
    if bad_fx > 0:
        anomalies.append(f"发现 {bad_fx} 笔换汇记录缺少目标币种或目标金额！")

    # 检查买卖无股票代码
    cur.execute("SELECT count(*) FROM transactions WHERE kind IN ('buy', 'sell') AND symbol = ''")
    bad_trades = cur.fetchone()[0]
    if bad_trades > 0:
        anomalies.append(f"发现 {bad_trades} 笔买卖记录缺少股票代码 (symbol)！")

    # 检查负数金额
    cur.execute("SELECT count(*) FROM transactions WHERE amount < 0")
    neg_amt = cur.fetchone()[0]
    if neg_amt > 0:
        anomalies.append(f"发现 {neg_amt} 笔金额为负数的异常记录！")

    if not anomalies:
        print("  [OK] 未发现数据结构异常，逻辑一致性校验通过。")
    else:
        for a in anomalies:
            print(f"  [WARN] {a}")

    conn.close()
    return total_tx

def main():
    local_tx = audit_database(LOCAL_DB, "本地数据库 (Local DB)")
    if os.path.exists(SYNC_DB):
        sync_tx = audit_database(SYNC_DB, "iCloud 同步数据库 (Sync DB)")
        if local_tx is not None and sync_tx is not None:
            print(f"\n==================================================")
            print(f" 双库同步校验:")
            if local_tx == sync_tx:
                print(f"  [OK] 本地与 iCloud 同步数据库记录总数一致 ({local_tx} 笔)。")
            else:
                print(f"  [WARN] 双库记录数不一致！本地: {local_tx}, 云盘: {sync_tx}，可能存在未完成同步。")
            print(f"==================================================")

if __name__ == '__main__':
    main()
