#!/usr/bin/env python3
"""
为记账页生成虚拟数据（仅本地开发用）。

用途：真实数据量太少时看不出「分类占比」的分布效果，也无法评估排版。

特点：
- 所有记录的 note 都以 `[demo]` 开头，便于一键清除（见 --clean）
- 金额、分类、日期都带真实感：餐饮小额高频、房租大额低频、工资每月一笔
- 生成最近 4 个月，每月 40~60 笔，让按月切换与每日走势都能看出形状

用法：
    python3 scripts/seed-ledger-demo.py                 # 生成
    python3 scripts/seed-ledger-demo.py --clean         # 清除
    python3 scripts/seed-ledger-demo.py --user kairo    # 指定账号（默认 kairo）
"""
import argparse
import random
import subprocess
import sys

DB_HOST = "127.0.0.1"
DB_PORT = "5432"
DB_USER = "dev"
DB_PASSWORD = "123456"
DB_NAME = "dev_db"
SCHEMA = "public"

MARK = "[demo]"
BATCH_PREFIX = "demo-batch-"

# (备注, 分类, 金额区间/元, 每月出现次数)
EXPENSE_POOL = [
    # 餐饮：高频小额
    ("午饭", "餐饮", (18, 45), 18),
    ("早饭", "餐饮", (6, 15), 14),
    ("晚饭", "餐饮", (25, 80), 12),
    ("咖啡", "餐饮", (18, 38), 10),
    ("奶茶", "餐饮", (12, 25), 6),
    ("聚餐", "餐饮", (80, 260), 2),
    ("外卖", "餐饮", (20, 55), 8),
    # 交通
    ("打车", "交通", (12, 60), 8),
    ("地铁", "交通", (3, 8), 12),
    ("加油", "交通", (300, 480), 1),
    # 购物：中额、有明显存在感
    ("超市", "购物", (60, 220), 5),
    ("日用品", "购物", (30, 120), 3),
    ("衣服", "购物", (150, 780), 2),
    ("数码", "购物", (400, 2400), 1),
    # 居家：大额低频，占比会很显眼
    ("房租", "居家", (2200, 2200), 1),
    ("水电煤", "居家", (120, 320), 1),
    ("物业", "居家", (80, 200), 1),
    # 娱乐
    ("电影", "娱乐", (35, 80), 2),
    ("游戏", "娱乐", (30, 200), 2),
    ("演出", "娱乐", (180, 480), 1),
    # 医疗
    ("药", "医疗", (20, 90), 2),
    ("挂号", "医疗", (10, 50), 1),
    # 还款：固定大额
    ("还信用卡", "还款", (1200, 2600), 1),
    # 订阅：小额固定
    ("icloud", "订阅", (6, 21), 1),
    ("applemusic", "订阅", (11, 11), 1),
    ("netflix", "订阅", (60, 60), 1),
    # Token：AI 服务，波动明显
    ("claude", "Token", (20, 160), 3),
    ("openai", "Token", (20, 200), 2),
    ("cursor", "Token", (140, 140), 1),
]

# (备注, 分类, 金额区间/元, 每月次数)
INCOME_POOL = [
    ("工资", "工资", (30000, 30000), 1),
    ("奖金", "奖金", (2000, 6000), 0.3),
    ("报销", "报销", (100, 900), 1.5),
    ("退款", "退款", (30, 400), 1),
    ("红包", "红包", (10, 200), 1),
]


def psql(sql: str) -> str:
    return subprocess.run(
        ["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", DB_NAME, "-tA", "-v", "ON_ERROR_STOP=1", "-c", sql],
        env={"PGPASSWORD": DB_PASSWORD, "PATH": "/usr/local/bin:/usr/bin:/bin"},
        capture_output=True,
        text=True,
        check=False,
    ).stdout


def run_sql(sql: str) -> None:
    result = subprocess.run(
        ["psql", "-h", DB_HOST, "-p", DB_PORT, "-U", DB_USER, "-d", DB_NAME, "-v", "ON_ERROR_STOP=1", "-q", "-c", sql],
        env={"PGPASSWORD": DB_PASSWORD, "PATH": "/usr/local/bin:/usr/bin:/bin"},
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        raise SystemExit(1)


def clean(user: str) -> None:
    """删除本脚本生成的数据：按 note 前缀 + batch 前缀双重标记。"""
    sql = f"""
    delete from {SCHEMA}.ledger_entries e
    where e.batch_id like '{BATCH_PREFIX}%'
      and e.user_id = (select id from {SCHEMA}.users where username = '{user}');

    delete from {SCHEMA}.ledger_batches b
    where b.batch_id like '{BATCH_PREFIX}%'
      and b.user_id = (select id from {SCHEMA}.users where username = '{user}');
    """
    run_sql(sql)
    print(f"已清除 {user} 的虚拟记账数据")


def build_rows(user_id: str, months: int) -> list[tuple]:
    """生成 (type, cents, category, note, occurred_at, batch_id) 列表。"""
    rows: list[tuple] = []
    today = __import__("datetime").date.today()
    rand = random.Random(42)  # 固定种子：每次生成的数据一致，便于对比布局

    for offset in range(months):
        # 从当前月往前推
        year = today.year
        month = today.month - offset
        while month <= 0:
            month += 12
            year -= 1

        import calendar

        days_in_month = calendar.monthrange(year, month)[1]
        # 当月只生成到今天为止
        last_day = today.day if offset == 0 else days_in_month
        if last_day < 1:
            last_day = 1

        batch_id = f"{BATCH_PREFIX}{year}{month:02d}"
        entries: list[tuple[str, int, str, str, str]] = []

        for note, category, (low, high), times in EXPENSE_POOL:
            count = int(times) if times >= 1 else (1 if rand.random() < times else 0)
            for _ in range(count):
                day = rand.randint(1, last_day)
                hour = rand.choice([7, 8, 12, 13, 18, 19, 20, 21])
                minute = rand.randint(0, 59)
                amount = rand.randint(low, high)
                occurred = f"{year}-{month:02d}-{day:02d} {hour:02d}:{minute:02d}:00+08:00"
                entries.append(("expense", amount * 100, category, f"{MARK} {note}", occurred))

        for note, category, (low, high), times in INCOME_POOL:
            count = int(times) if times >= 1 else (1 if rand.random() < times else 0)
            for _ in range(count):
                day = rand.randint(1, last_day)
                amount = rand.randint(low, high)
                occurred = f"{year}-{month:02d}-{day:02d} 10:00:00+08:00"
                entries.append(("income", amount * 100, category, f"{MARK} {note}", occurred))

        for typ, cents, category, note, occurred in entries:
            rows.append((typ, cents, category, note, occurred, batch_id))

    return rows


def seed(user: str, months: int) -> None:
    user_id = psql(f"select id from {SCHEMA}.users where username = '{user}'").strip()
    if not user_id:
        print(f"找不到用户 {user}", file=sys.stderr)
        raise SystemExit(1)

    clean(user)
    rows = build_rows(user_id, months)

    # 按批次分组写入，并建立 ledger_batches（V11 起 entries 有指向 batches 的外键）
    batches = sorted({r[5] for r in rows})
    values_batches = ",".join(f"('{user_id}','{b}','demo seed')" for b in batches)
    run_sql(
        f"insert into {SCHEMA}.ledger_batches (user_id, batch_id, raw_text) values {values_batches} "
        f"on conflict do nothing"
    )

    def esc(text: str) -> str:
        return text.replace("'", "''")

    values_entries = ",".join(
        f"('{user_id}','{t}',{c},'{esc(cat)}','{esc(note)}','{occ}','{bid}')"
        for t, c, cat, note, occ, bid in rows
    )
    run_sql(
        f"insert into {SCHEMA}.ledger_entries "
        f"(user_id, type, amount_cents, category, note, occurred_at, batch_id) values {values_entries}"
    )

    print(f"已为 {user} 生成 {len(rows)} 笔虚拟记账数据（最近 {months} 个月）")
    print(f"标记：note 以 {MARK} 开头，batch_id 以 {BATCH_PREFIX} 开头")
    print(f"清除：python3 scripts/seed-ledger-demo.py --clean --user {user}")


def main() -> None:
    parser = argparse.ArgumentParser(description="生成/清除记账页虚拟数据")
    parser.add_argument("--user", default="kairo", help="账号（默认 kairo）")
    parser.add_argument("--months", type=int, default=4, help="生成最近几个月（默认 4）")
    parser.add_argument("--clean", action="store_true", help="只清除虚拟数据")
    args = parser.parse_args()

    if args.clean:
        clean(args.user)
        return
    seed(args.user, args.months)


if __name__ == "__main__":
    main()
