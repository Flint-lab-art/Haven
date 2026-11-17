#!/usr/bin/env python3
"""
把微信 / 支付宝导出的年度账单合并、清洗，输出一份可直接导入的 CSV。

为什么需要这一步：两个平台导出的格式不同，且都混着大量「不是消费」的记录。
直接导入会污染统计，所以先清洗：

**丢弃**
- 提现 / 充值 / 理财 / 零钱通存取：钱只是换了个地方
- 转账红包、亲友代付、信用借还（还款）：不是消费或已有债务
- 交易关闭 / 解冻失败：钱没花出去
- 金额为 0：医保代付那类，没有记账意义
- 退款记录：改为在支出侧扣减（见下）

**退款处理（净额法）**
微信把「支出后退款」记成两条：一条支出、一条退款收入。
两条都算会让支出和收入同时虚增，所以改为：
- 全额退款 → 整笔丢弃
- 部分退款 → 支出减为净额（如花 40 退 13.33，记为支出 26.67）

**输出**
CSV（UTF-8 BOM，Excel 可直接打开），列：
日期,时间,类型,金额,对方,商品说明,状态,来源,交易单号,建议分类

「建议分类」优先用支付宝自带的交易分类映射，微信按关键词兜底；
导入页面里可以逐条修改。

用法：
    python3 scripts/merge-bills.py 微信账单.xlsx 支付宝账单.csv [-o 输出.csv]
"""

import argparse
import csv
import re
import zipfile
from xml.etree import ElementTree as ET
from datetime import datetime, timedelta
from decimal import Decimal
from collections import Counter

NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
ns = {'m': NS[1:-1]}

def read_wechat(path):
    z = zipfile.ZipFile(path)
    shared = []
    root = ET.fromstring(z.read('xl/sharedStrings.xml'))
    for si in root.findall('m:si', ns):
        shared.append(''.join(t.text or '' for t in si.iter(NS + 't')))
    sheet = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows = []
    for row in sheet.iter(NS + 'row'):
        vals = []
        for c in row:
            t = c.get('t'); v = c.find('m:v', ns)
            if t == 's' and v is not None: vals.append(shared[int(v.text)])
            else: vals.append(v.text if v is not None else '')
        rows.append(vals)
    hdr = next(i for i,r in enumerate(rows) if r and r[0] == '交易时间')
    out = []
    for r in rows[hdr+1:]:
        if len(r) < 9 or not r[0]: continue
        try: dt = datetime(1899,12,30) + timedelta(days=float(r[0]))
        except ValueError: continue
        out.append(dict(time=dt, dir=r[4], amount=r[5], peer=r[2], desc=r[3],
                        status=r[7], no=r[8].strip(), src='微信', kind=r[1]))
    return out

def read_alipay(path):
    raw = open(path,'rb').read().decode('gbk')
    lines = raw.splitlines()
    hdr = next(i for i,l in enumerate(lines) if l.startswith('交易时间,'))
    reader = csv.reader(lines[hdr:]); next(reader)
    out = []
    for r in reader:
        if len(r) < 10 or not r[0]: continue
        out.append(dict(time=datetime.strptime(r[0],'%Y-%m-%d %H:%M:%S'), dir=r[5], amount=r[6],
                        peer=r[2], desc=r[4], status=r[8], no=r[9].strip(), src='支付宝', kind=r[1]))
    return out


FULL_REFUND = re.compile(r'已全额退款')
PART_REFUND = re.compile(r'已退款[\(（]?¥([\d.]+)[\)）]?')

# ---- 建议分类：优先用支付宝自带的交易分类，微信按关键词兜底 ----
ALI_MAP = {
    '餐饮美食': '餐饮', '日用百货': '购物', '生活服务': '居家', '交通出行': '交通',
    '文化休闲': '娱乐', '医疗健康': '医疗', '数码电器': '购物', '充值缴费': '居家',
    '家居家装': '居家', '运动户外': '娱乐', '教育培训': '订阅', '服饰装扮': '购物',
    '酒店旅游': '娱乐', '美容美发': '医疗', '宠物': '娱乐', '爱车养车': '交通',
    '公共服务': '居家', '保险': '订阅', '商业服务': '其他收入', '其他': '未分类',
}

# 微信没有分类字段，按对方/商品的关键词兜底
WX_RULES = [
    (('餐', '饭', '面', '粉', '粥', '炸', '串', '饼', '鸡', '奶茶', '咖啡', '便利', '零食', '果', '菜',
      '食堂', '米线', '麻辣烫', '汉堡', '烤', '蛋糕', '包', '食', '旺'), '餐饮'),
    (('地铁', '打车', '高德', '出行', '铁路', '12306', '公交', '加油', '停车', '哈啰', '单车', '中充'), '交通'),
    (('云', '腾讯', '阿里', '京东', '拼多多', '淘宝', '商城', '商城', '超市', '百货', '店'), '购物'),
    (('药', '医院', '医科', '诊所', '口腔', '体检'), '医疗'),
    (('电影', '游戏', '美团', '影', '演出', '票'), '娱乐'),
    (('icloud', 'apple music', 'appletv', '订阅', '会员', 'netflix', '腾讯视频', '爱奇艺', '网易云'), '订阅'),
    (('openai', 'claude', 'deepseek', 'token', 'api'), 'Token'),
    (('房租', '物业', '水电', '话费', '移动', '联通', '电信'), '居家'),
]

def guess(r):
    if r['src'] == '支付宝':
        return ALI_MAP.get(r['kind'], '未分类')
    if r['dir'] == '收入':
        if '红包' in r['kind']: return '红包'
        if '退款' in r['kind']: return '退款'
        return '其他收入'
    hay = f"{r['peer']} {r['desc']}".lower()
    for words, cat in WX_RULES:
        if any(w.lower() in hay for w in words):
            return cat
    return '未分类'


def merge_and_write(w: list, a: list, out: str) -> None:
    """把两平台的原始记录清洗并写出 CSV。"""
    rows = []
    dropped = Counter()
    seen = set()

    for r in w + a:
        d = r['dir']
        amt = Decimal(r['amount'])

        # 只处理支出与收入；提现/转账/理财/不计收支一律丢弃
        if d not in ('支出', '收入'):
            if '退款' in r['status'] or r['kind'] == '退款':
                dropped['退款/冲正记录（已在支出侧扣减）'] += 1
            else:
                dropped['提现/转账/理财/不计收支'] += 1
            continue

        if amt == 0:
            dropped['零金额'] += 1
            continue

        # 资金流转类（仅支出侧）：小荷包自动攒、信用卡/网贷还款、转给他人
        # 这些不是消费，是「自己的钱换了个地方」或偿还既有债务。
        # 收入侧的转账/红包是实打实的进账，不能丢。
        FLOW_KINDS = {'账户存取', '信用借还', '转账红包', '亲友代付', '投资理财'}
        if d == '支出' and r['kind'] in FLOW_KINDS:
            dropped[f'资金流转（{r["kind"]}）'] += 1
            continue

        # 交易关闭 / 解冻失败 = 钱没花出去，整笔不计
        if '关闭' in r['status'] or '解冻' in r['status']:
            dropped['交易关闭/未成交'] += 1
            continue

        key = (r['no'], d)
        if key in seen:
            dropped['单号重复'] += 1
            continue
        seen.add(key)

        # 微信部分退款：支出净额 = 原额 - 退款额
        if d == '支出':
            m_part = PART_REFUND.search(r['status'])
            if FULL_REFUND.search(r['status']):
                dropped['全额退款（整笔不计）'] += 1
                continue
            if m_part and '已退款(' in r['status'] or (m_part and '已退款（' in r['status']):
                refunded = Decimal(m_part.group(1))
                net = amt - refunded
                dropped[f'部分退款扣减 ¥{refunded}'] += 1
                if net <= 0:
                    continue
                amt = net

        rows.append(dict(
            date=r['time'].strftime('%Y-%m-%d'),
            time=r['time'].strftime('%H:%M:%S'),
            type='收入' if d == '收入' else '支出',
            amount=f'{amt:.2f}',
            peer=r['peer'].strip() or '/',
            desc=r['desc'].strip() if r['desc'].strip() not in ('', '/') else '',
            status=r['status'],
            source=r['src'],
            trade_no=r['no'],
            _cat=guess(r),
        ))

    rows.sort(key=lambda x: (x['date'], x['time']))

    with open(out, 'w', newline='', encoding='utf-8-sig') as f:
        wtr = csv.DictWriter(f, fieldnames=['日期','时间','类型','金额','对方','商品说明','状态','来源','交易单号','建议分类'])
        wtr.writeheader()
        for r in rows:
            wtr.writerow({'日期':r['date'],'时间':r['time'],'类型':r['type'],'金额':r['amount'],
                          '对方':r['peer'],'商品说明':r['desc'],'状态':r['status'],
                          '来源':r['source'],'交易单号':r['trade_no'],'建议分类':r['_cat']})

    exp = sum(Decimal(r['amount']) for r in rows if r['type']=='支出')
    inc = sum(Decimal(r['amount']) for r in rows if r['type']=='收入')
    print(f'输出 {out}：{len(rows)} 条')
    print(f'  支出 {sum(1 for r in rows if r["type"]=="支出")} 笔  ¥{exp}')
    print(f'  收入 {sum(1 for r in rows if r["type"]=="收入")} 笔  ¥{inc}')
    print(f'  净支出 ¥{exp-inc}')
    print('\n丢弃明细:')
    for k, v in dropped.most_common():
        print(f'  {k}: {v}')



def main() -> None:
    parser = argparse.ArgumentParser(description='合并清洗微信/支付宝年度账单')
    parser.add_argument('wechat', help='微信导出的 .xlsx')
    parser.add_argument('alipay', help='支付宝导出的 .csv')
    parser.add_argument('-o', '--out', default='账单汇总.csv', help='输出文件名（默认 账单汇总.csv）')
    args = parser.parse_args()

    w = read_wechat(args.wechat)
    a = read_alipay(args.alipay)
    merge_and_write(w, a, args.out)


if __name__ == '__main__':
    main()
