#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EmojiTool - WYChatView表情资源管理工具

用法(python3 EmojiTool.py <命令> [参数]):
  verify                          校验plist/png/gif三向一致性(数量、一一对应、重名、LICENSE)
  scan                            按三维评分(完整度50%+鲜艳度30%+居中度20%)重刷全部静态图
  sheet <表情名>                   铺某表情的全部帧编号对照图到桌面(红框=当前静态帧), 用于人工挑帧
  static <表情名> --frame N        把某表情的静态图换成gif里的第N帧
  add <gif路径> <表情名> [--after 某表情]   导入新表情gif并生成三维评分静态图, 插入plist(默认追加到末尾)
  bake <表情名> --frame N --first|--last [--keep-static] [--dry-run]
                                  把gif里的第N帧烧进动画首/尾(未来面板直接显示首/尾帧即可省掉静态图)
  migrate --first|--last [--dry-run]
                                  批量把现有静态图(即人工定稿帧)烧进所有gif的首/尾并删静态图, 迁移到单文件方案

说明:
  - 表情名可不带方括号(写"微笑"或"[微笑]"都行)
  - bake/migrate会重写gif文件, 先用--dry-run预览将要发生的变更
  - 可用环境变量WY_EMOJI_DIR覆盖表情目录(测试用): WY_EMOJI_DIR=/tmp/test python3 EmojiTool.py verify
"""
import os
import plistlib
import sys
import tempfile
from PIL import Image, ImageDraw, ImageFont

# 表情目录从脚本自身位置推导(脚本在仓库根目录), 不写死绝对路径
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
EMOJI_DIR = os.environ.get('WY_EMOJI_DIR') or os.path.join(
    SCRIPT_DIR, 'WYBasisKit', 'WYBasisKit', 'WYBasisKit',
    'Swift', 'Layout', 'ChatView', 'WYChatView.bundle', 'WYChatViewEmoji')
PLIST_PATH = os.path.join(os.path.dirname(EMOJI_DIR), 'WYChatViewEmoji.plist')
LICENSE_NAME = 'LICENSE.txt'
DESKTOP = os.path.expanduser('~/Desktop')
FONT_PATH = '/System/Library/Fonts/STHeiti Medium.ttc'
W_COV, W_SAT, W_CEN = 0.5, 0.3, 0.2  # 三维评分权重


def log(msg):
    print(msg, flush=True)


def die(msg):
    print(f'错误: {msg}', file=sys.stderr)
    sys.exit(1)


def plain_name(name):
    """表情名去方括号(写[微笑]或微笑都归一成微笑)"""
    return name.strip().strip('[]')


def gif_path(name):
    return os.path.join(EMOJI_DIR, f'[{plain_name(name)}].gif')


def png_path(name):
    return os.path.join(EMOJI_DIR, f'[{plain_name(name)}].png')


def load_plist():
    with open(PLIST_PATH, 'rb') as f:
        return [plain_name(n) for n in plistlib.load(f)]


def save_plist(names):
    with open(PLIST_PATH, 'wb') as f:
        plistlib.dump([f'[{n}]' for n in names], f)


def load_gif_frames(path):
    """读出gif全部帧(RGBA)与每帧时长(ms)"""
    img = Image.open(path)
    frames, durations = [], []
    for i in range(getattr(img, 'n_frames', 1)):
        img.seek(i)
        frames.append(img.convert('RGBA'))
        durations.append(max(img.info.get('duration', 50), 20))
    return frames, durations


def save_gif_frames(path, frames, durations):
    """按透明配方重写gif(透明像素统一指向调色板索引255, disposal=2防帧残留)"""
    palette_frames = []
    for rgba in frames:
        if rgba.size != (96, 96):
            rgba = rgba.resize((96, 96), Image.LANCZOS)
        alpha = rgba.getchannel('A')
        p = rgba.convert('RGB').quantize(colors=255, method=Image.FASTOCTREE)
        p.paste(255, alpha.point(lambda a: 255 if a < 128 else 0))
        palette_frames.append(p)
    palette_frames[0].save(path, format='GIF', save_all=True,
                           append_images=palette_frames[1:],
                           duration=durations, loop=0,
                           transparency=255, disposal=2, optimize=True)


def frame_metrics(rgba):
    """单帧三维指标: 不透明像素量, 平均饱和度, 居中度(质心离画面中心越近越高)"""
    w, h = rgba.size
    cx, cy = (w - 1) / 2, (h - 1) / 2
    hpx = list(rgba.convert('HSV').getdata())
    cov = sat_sum = sx = sy = n = 0
    for idx, (r, g, b, a) in enumerate(rgba.getdata()):
        if a > 40:
            cov += 1
            sat_sum += hpx[idx][1]
            sx += idx % w
            sy += idx // w
            n += 1
    if n == 0:
        return 0, 0.0, 0.0
    dist = ((sx / n - cx) ** 2 + (sy / n - cy) ** 2) ** 0.5
    max_dist = (cx ** 2 + cy ** 2) ** 0.5
    return cov, sat_sum / n, 1.0 - dist / max_dist


def norm(vals):
    lo, hi = min(vals), max(vals)
    return [0.5] * len(vals) if hi == lo else [(v - lo) / (hi - lo) for v in vals]


def best_frame_index(frames):
    """三维评分选出形态最完整的一帧(返回帧号)"""
    metrics = [frame_metrics(f) for f in frames]
    ncov = norm([m[0] for m in metrics])
    nsat = norm([m[1] for m in metrics])
    ncen = norm([m[2] for m in metrics])
    scores = [W_COV * ncov[i] + W_SAT * nsat[i] + W_CEN * ncen[i] for i in range(len(frames))]
    return max(range(len(frames)), key=lambda i: scores[i])


def save_static(frame, name):
    """静态图统一96px"""
    if frame.size != (96, 96):
        frame = frame.resize((96, 96), Image.LANCZOS)
    frame.save(png_path(name), optimize=True)


def find_static_index(frames, name):
    """定位当前静态图对应gif里的哪一帧(找不到返回-1)"""
    if not os.path.exists(png_path(name)):
        return -1
    cur = Image.open(png_path(name)).convert('RGBA')
    cur_data = list(cur.getdata())
    for i, f in enumerate(frames):
        if f.size == cur.size and list(f.getdata()) == cur_data:
            return i
    return -1


# ---------- 命令实现 ----------

def cmd_verify(_):
    names = load_plist()
    files = os.listdir(EMOJI_DIR)
    pngs = {f[1:-5] for f in files if f.startswith('[') and f.endswith('].png')}
    gifs = {f[1:-5] for f in files if f.startswith('[') and f.endswith('].gif')}
    problems = []
    if len(names) != len(set(names)):
        problems.append(f'plist有重名, 共{len(names)}条/{len(set(names))}个唯一')
    if set(names) != pngs:
        problems.append(f'plist与png不一致, plist多: {sorted(set(names) - pngs)[:5]}, png多: {sorted(pngs - set(names))[:5]}')
    if gifs - pngs:
        problems.append(f'gif没有同名png: {sorted(gifs - pngs)[:5]}')
    if pngs - gifs:
        problems.append(f'png没有同名gif: {sorted(pngs - gifs)[:5]}')
    if LICENSE_NAME not in files:
        problems.append('缺少LICENSE.txt')
    extras = [f for f in files if not (f.startswith('[') or f == LICENSE_NAME) and not f.endswith(('.png', '.gif'))]
    if extras:
        problems.append(f'目录有意外文件: {extras[:5]}')
    if problems:
        for p in problems:
            log(f'  ✗ {p}')
        die(f'校验未通过, 共{len(problems)}个问题')
    log(f'✓ 校验通过: plist {len(names)} | png {len(pngs)} | gif {len(gifs)}, 一一对应, LICENSE在位')


def cmd_scan(_):
    gifs = sorted(f for f in os.listdir(EMOJI_DIR) if f.startswith('[') and f.endswith('].gif'))
    changed = 0
    for f in gifs:
        name = f[1:-5]
        frames, _ = load_gif_frames(os.path.join(EMOJI_DIR, f))
        best = best_frame_index(frames)
        old_i = find_static_index(frames, name)
        if old_i != best:
            save_static(frames[best], name)
            changed += 1
            log(f'  [{name}] 第{old_i}帧 -> 第{best}帧')
    log(f'✓ scan完成: {len(gifs)}个表情, 换帧{changed}个')


def cmd_sheet(args):
    if not args:
        die('用法: sheet <表情名>')
    name = plain_name(args[0])
    path = gif_path(name)
    if not os.path.exists(path):
        die(f'找不到 {path}')
    frames, _ = load_gif_frames(path)
    cur_i = find_static_index(frames, name)
    font = ImageFont.truetype(FONT_PATH, 18)
    cols = 10
    rows = (len(frames) + cols - 1) // cols
    cell, label_h = 96, 26
    sheet = Image.new('RGB', (cols * cell + 20, rows * (cell + label_h) + 20), (250, 250, 252))
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(frames):
        x, y = 10 + (i % cols) * cell, 10 + (i // cols) * (cell + label_h)
        sheet.paste(f.resize((88, 88), Image.LANCZOS), (x, y), f.resize((88, 88), Image.LANCZOS))
        if i == cur_i:
            d.rectangle([x - 1, y - 1, x + 92, y + 92], outline=(220, 40, 40), width=4)
            d.text((x + 18, y + 96), f'{i} 当前', fill=(220, 40, 40), font=font)
        else:
            d.text((x + 34, y + 96), str(i), fill=(90, 90, 90), font=font)
    out = os.path.join(DESKTOP, f'{name}-帧序列对照.png')
    sheet.save(out)
    log(f'✓ [{name}] 共{len(frames)}帧已铺开(当前静态=第{cur_i}帧): {out}')


def cmd_static(args):
    name, frame = None, None
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--frame':
            i += 1
            if i >= len(args):
                die('--frame 缺参数')
            frame = int(args[i])
        else:
            name = a
        i += 1
    if name is None or frame is None:
        die('用法: static <表情名> --frame N')
    path = gif_path(name)
    frames, _ = load_gif_frames(path)
    if not 0 <= frame < len(frames):
        die(f'帧号超范围, [{plain_name(name)}]共{len(frames)}帧(0~{len(frames) - 1})')
    save_static(frames[frame], name)
    log(f'✓ [{plain_name(name)}] 静态图已换成第{frame}帧')


def cmd_add(args):
    if len(args) < 2:
        die('用法: add <gif路径> <表情名> [--after 某表情]')
    src, name = args[0], plain_name(args[1])
    after = None
    if '--after' in args:
        after = plain_name(args[args.index('--after') + 1]) if len(args) > args.index('--after') + 1 else die('--after 缺参数')
    if not os.path.exists(src):
        die(f'找不到源文件 {src}')
    names = load_plist()
    if name in names:
        die(f'[{name}] 已存在')
    frames, durations = load_gif_frames(src)
    save_gif_frames(gif_path(name), frames, durations)
    best = best_frame_index(frames)
    save_static(frames[best], name)
    if after:
        if after not in names:
            die(f'锚点表情[{after}]不存在')
        names.insert(names.index(after) + 1, name)
    else:
        names.append(name)
    save_plist(names)
    log(f'✓ [{name}] 已导入({len(frames)}帧, 静态取三维评分第{best}帧), plist共{len(names)}个')


def cmd_bake(args):
    name, frame, pos, keep, dry = None, None, None, False, False
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--frame':
            i += 1
            frame = int(args[i])
        elif a in ('--first', '--last'):
            pos = a[2:]
        elif a == '--keep-static':
            keep = True
        elif a == '--dry-run':
            dry = True
        else:
            name = a
        i += 1
    if name is None or frame is None or pos is None:
        die('用法: bake <表情名> --frame N --first|--last [--keep-static] [--dry-run]')
    name = plain_name(name)
    path = gif_path(name)
    frames, durations = load_gif_frames(path)
    if not 0 <= frame < len(frames):
        die(f'帧号超范围, 共{len(frames)}帧')
    insert_at = 0 if pos == 'first' else len(frames)
    plan = (f'[{name}] 把第{frame}帧烧进{"首" if pos == "first" else "尾"}部 '
            f'({len(frames)}帧->{len(frames) + 1}帧), {"保留" if keep else "删除"}静态图')
    if dry:
        log(f'[dry-run] 将执行: {plan}')
        return
    chosen = frames[frame]
    frames.insert(insert_at, chosen)
    durations.insert(insert_at, durations[frame])
    save_gif_frames(path, frames, durations)
    if not keep:
        os.remove(png_path(name))
    log(f'✓ {plan}')


def cmd_migrate(args):
    pos, dry = None, False
    for a in args:
        if a in ('--first', '--last'):
            pos = a[2:]
        elif a == '--dry-run':
            dry = True
    if pos is None:
        die('用法: migrate --first|--last [--dry-run]')
    names = load_plist()
    total, skipped = 0, 0
    for name in names:
        path = gif_path(name)
        frames, durations = load_gif_frames(path)
        static_i = find_static_index(frames, name)
        if static_i < 0 or not os.path.exists(png_path(name)):
            skipped += 1
            log(f'  跳过 [{name}] (静态图不在gif帧序列里或没有静态图)')
            continue
        plan = f'[{name}] 第{static_i}帧烧进{"首" if pos == "first" else "尾"}部并删静态图'
        if dry:
            log(f'[dry-run] {plan}')
        else:
            chosen = frames[static_i]
            insert_at = 0 if pos == 'first' else len(frames)
            frames.insert(insert_at, chosen)
            durations.insert(insert_at, durations[static_i])
            save_gif_frames(path, frames, durations)
            os.remove(png_path(name))
            log(f'  ✓ {plan}')
        total += 1
    tail = '处理%d个, 跳过%d个' % (total, skipped)
    if dry:
        log(f'✓ migrate[dry-run]: {tail}')
    else:
        hint = ', 迁移后面板显示端取' + ('首帧' if pos == 'first' else '末帧')
        log(f'✓ migrate完成: {tail}{hint}')


COMMANDS = {
    'verify': cmd_verify,
    'scan': cmd_scan,
    'sheet': cmd_sheet,
    'static': cmd_static,
    'add': cmd_add,
    'bake': cmd_bake,
    'migrate': cmd_migrate,
}


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ('-h', '--help', 'help'):
        print(__doc__)
        return
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        die(f'未知命令 {cmd}, 运行 python3 EmojiTool.py help 查看用法')
    if not os.path.isdir(EMOJI_DIR):
        die(f'表情目录不存在: {EMOJI_DIR}')
    COMMANDS[cmd](sys.argv[2:])


if __name__ == '__main__':
    main()
