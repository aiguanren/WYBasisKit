#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EmojiTool - WYChatView表情资源管理工具

用法(python3 EmojiTool.py <命令> [参数]):
  verify                          校验plist/png/gif三向一致性(数量、一一对应、重名、LICENSE)
  scan                            按三维评分(完整度50%+鲜艳度30%+居中度20%)重刷全部静态图
  sheet <表情名>                   铺某表情的全部帧编号对照图到桌面(红框=当前静态帧), 用于人工挑帧
  static <表情名> --frame N        把某表情的静态图换成gif里的第N帧
  move <表情名> --before|--after <锚点表情>   修改表情在plist中的位置(即面板显示顺序)
  add <gif路径> <表情名> [--after 某表情]   导入新表情gif并生成三维评分静态图, 插入plist(默认追加到末尾)
  bake <表情名> --frame N --first|--last [--keep-static] [--dry-run]
                                  把gif里的第N帧烧进动画首/尾(未来面板直接显示首/尾帧即可省掉静态图)
  migrate --first|--last [--dry-run]
                                  批量把现有静态图(即人工定稿帧)烧进所有gif的首/尾并删静态图, 迁移到单文件方案
  convert <表情名或文件路径> --to apng|gif|webp|frames [--lossy] [--keep-source] [--dry-run]
                                  GIF/APNG/WebP互转或导出帧序列: 传表情名按bundle约定落位(gif转apng/webp生成
                                  apng_[名].png/webp_[名].webp并删gif, apng/webp转gif生成[名].gif并删源),
                                  传文件路径则原地同名互转; --to frames把动画导出成编号PNG序列(桌面目录 名-帧序列/);
                                  也可传帧序列目录反向合成: convert <帧序列目录> --to gif|apng [--out 输出路径]

说明:
  - 表情名可不带方括号(写"微笑"或"[微笑]"都行)
  - bake/migrate/convert会重写或删除文件, 先用--dry-run预览将要发生的变更
  - 可用环境变量WY_EMOJI_DIR覆盖表情目录(测试用): WY_EMOJI_DIR=/tmp/test python3 EmojiTool.py verify
"""
import os
import plistlib
import sys
import tempfile
from PIL import Image, ImageDraw, ImageFont

# 表情目录从脚本自身位置推导(脚本就放在表情目录里), 不写死绝对路径
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
EMOJI_DIR = os.environ.get('WY_EMOJI_DIR') or SCRIPT_DIR
PLIST_PATH = os.path.join(os.path.dirname(EMOJI_DIR), 'WYChatViewEmoji.plist')
LICENSE_NAME = 'LICENSE.txt'
TOOL_NAME = 'EmojiTool.py'
DESKTOP = os.path.expanduser('~/Desktop')
FONT_PATH = '/System/Library/Fonts/STHeiti Medium.ttc'
W_COV, W_SAT, W_CEN = 0.5, 0.3, 0.2  # 三维评分权重

# 提示配色: 成功绿/失败红/dry-run黄/提示灰, 按消息内容自动匹配
ANSI = {'bold': '\033[1m', 'green': '\033[32m', 'red': '\033[31m', 'yellow': '\033[33m', 'cyan': '\033[36m', 'dim': '\033[90m', 'reset': '\033[0m'}


def log(msg):
    stripped = msg.lstrip()
    if stripped.startswith('✓'):
        msg = ANSI['green'] + msg + ANSI['reset']
    elif stripped.startswith('✗'):
        msg = ANSI['red'] + msg + ANSI['reset']
    elif stripped.startswith('[dry-run]'):
        msg = ANSI['yellow'] + msg + ANSI['reset']
    elif stripped.startswith('提示'):
        msg = ANSI['dim'] + msg + ANSI['reset']
    print(msg, flush=True)


def die(msg):
    print(f"{ANSI['red']}错误: {msg}{ANSI['reset']}", file=sys.stderr)
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
    extras = [f for f in files if not (f.startswith('[') or f in (LICENSE_NAME, TOOL_NAME)) and not f.endswith(('.png', '.gif'))]
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


def cmd_convert(args):
    target, to_fmt, keep, dry, lossy, out_path = None, None, False, False, False, None
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--to':
            i += 1
            if i >= len(args):
                die('--to 缺参数(apng/gif/webp/frames)')
            to_fmt = args[i].lower()
        elif a == '--keep-source':
            keep = True
        elif a == '--dry-run':
            dry = True
        elif a == '--lossy':
            lossy = True
        elif a == '--out':
            i += 1
            if i >= len(args):
                die('--out 缺参数')
            out_path = args[i]
        else:
            target = a
        i += 1
    if target is None or to_fmt not in ('apng', 'gif', 'webp', 'frames'):
        die('用法: convert <表情名或文件路径或帧序列目录> --to apng|gif|webp|frames [--lossy] [--out 路径] [--keep-source] [--dry-run]')

    # 帧序列目录模式: 编号PNG合成gif/apng
    if os.path.isdir(target):
        if to_fmt not in ('gif', 'apng'):
            die('帧序列目录只能合成gif或apng')
        frame_files = sorted(f for f in os.listdir(target) if f.endswith('.png'))
        if not frame_files:
            die(f'目录里没有png帧: {target}')
        frames = [Image.open(os.path.join(target, f)).convert('RGBA') for f in frame_files]
        durations = [80] * len(frames)
        dst = out_path or os.path.join(os.path.dirname(target.rstrip('/')),
                                       os.path.basename(target.rstrip('/')) + ('.gif' if to_fmt == 'gif' else '.png'))
        _write_animation(dst, frames, durations, to_fmt, lossy)
        log(f'✓ {len(frame_files)}帧({frame_files[0]}..{frame_files[-1]}) 合成为 {dst}')
        return

    # 导出帧序列模式: 动画拆成编号PNG(桌面目录或--out指定目录)
    if to_fmt == 'frames':
        if os.path.isfile(target):
            src_path = target
            name = os.path.splitext(os.path.basename(target))[0]
        else:
            name = plain_name(target)
            src_path = gif_path(name)
            if not os.path.exists(src_path):
                src_path = os.path.join(EMOJI_DIR, f'apng_[{name}].png')
            if not os.path.exists(src_path):
                src_path = os.path.join(EMOJI_DIR, f'webp_[{name}].webp')
            if not os.path.exists(src_path):
                die(f'找不到 [{name}] 的动画文件(gif/apng/webp)')
        frames, _ = load_gif_frames(src_path)
        out_dir = out_path or os.path.join(DESKTOP, f'{name}-帧序列')
        os.makedirs(out_dir, exist_ok=True)
        for i, f in enumerate(frames):
            f.save(os.path.join(out_dir, f'f{i:04d}.png'), optimize=True)
        log(f'✓ [{name}] {len(frames)}帧已导出到 {out_dir}/ (f0000.png~f{len(frames) - 1:04d}.png)')
        return

    # 独立文件模式: 原地同名互转
    if os.path.isfile(target):
        src_path = target
        src_ext = os.path.splitext(src_path)[1].lower()
        if to_fmt == 'gif' and src_ext == '.gif':
            die('源文件已是gif')
        if to_fmt != 'gif' and src_ext == ('.png' if to_fmt == 'apng' else '.webp'):
            die(f'源文件已是{to_fmt}')
        dst_ext = {'apng': '.png', 'gif': '.gif', 'webp': '.webp'}[to_fmt]
        dst_path = os.path.splitext(src_path)[0] + dst_ext
        frames, durations = load_gif_frames(src_path)
        plan = f'{os.path.basename(src_path)}({len(frames)}帧) -> {os.path.basename(dst_path)}, {"保留" if keep else "删除"}源文件'
        if dry:
            log(f'[dry-run] 将执行: {plan}')
            return
        _write_animation(dst_path, frames, durations, to_fmt, lossy)
        if not keep:
            os.remove(src_path)
        log(f'✓ {plan}')
        return

    # bundle表情模式: apng/webp用前缀约定落位, gif用[名].gif
    name = plain_name(target)
    if to_fmt == 'gif':
        src_path = os.path.join(EMOJI_DIR, f'apng_[{name}].png')
        src_path = src_path if os.path.exists(src_path) else os.path.join(EMOJI_DIR, f'webp_[{name}].webp')
        dst_path = gif_path(name)
    else:
        src_path = gif_path(name)
        prefix, ext = ('apng_', '.png') if to_fmt == 'apng' else ('webp_', '.webp')
        dst_path = os.path.join(EMOJI_DIR, f'{prefix}[{name}]{ext}')
    if not os.path.exists(src_path):
        die(f'找不到 {src_path}')
    frames, durations = load_gif_frames(src_path)
    plan = (f'[{name}] {os.path.basename(src_path)}({len(frames)}帧) -> {os.path.basename(dst_path)}, '
            f'{"保留" if keep else "删除"}源文件')
    if dry:
        log(f'[dry-run] 将执行: {plan}')
        return
    _write_animation(dst_path, frames, durations, to_fmt, lossy)
    if not keep:
        os.remove(src_path)
    log(f'✓ {plan}')
    if to_fmt == 'webp':
        log('  提示: 预览探测链当前为gif->apng->静态, webp_通道需等代码侧支持后生效')
    else:
        log(f'  提示: 预览探测链为gif->apng->静态, {"转apng后走apng_通道" if to_fmt == "apng" else "转gif后优先走gif通道"}')


def _write_animation(path, frames, durations, to_fmt, lossy=False):
    """按目标格式写动画文件(apng/webp保留全透明通道, gif走透明配方, webp默认无损)"""
    norm = [f.resize((96, 96), Image.LANCZOS) if f.size != (96, 96) else f for f in frames]
    if to_fmt == 'apng':
        norm[0].save(path, format='PNG', save_all=True, append_images=norm[1:],
                     duration=durations, loop=0)
    elif to_fmt == 'webp':
        kwargs = {'quality': 80} if lossy else {'lossless': True}
        norm[0].save(path, format='WEBP', save_all=True, append_images=norm[1:],
                     duration=durations, loop=0, **kwargs)
    else:
        save_gif_frames(path, frames, durations)


def cmd_move(args):
    name, anchor, rel = None, None, None
    i = 0
    while i < len(args):
        a = args[i]
        if a in ('--before', '--after'):
            i += 1
            if i >= len(args):
                die(f'{a} 缺参数(锚点表情名)')
            rel, anchor = a[2:], args[i]
        else:
            name = a
        i += 1
    if name is None or anchor is None or rel is None:
        die('用法: move <表情名> --before|--after <锚点表情>')
    name, anchor = plain_name(name), plain_name(anchor)
    names = load_plist()
    if name not in names:
        die(f'[{name}] 不在plist里')
    if anchor not in names:
        die(f'锚点表情[{anchor}]不在plist里')
    if name == anchor:
        die('不能以自己为锚点')
    names.remove(name)
    idx = names.index(anchor)
    names.insert(idx if rel == 'before' else idx + 1, name)
    save_plist(names)
    log(f'✓ [{name}] 已移到[{anchor}]{"前面" if rel == "before" else "后面"}, plist共{len(names)}个')


COMMANDS = {
    'verify': cmd_verify,
    'scan': cmd_scan,
    'sheet': cmd_sheet,
    'static': cmd_static,
    'move': cmd_move,
    'add': cmd_add,
    'bake': cmd_bake,
    'migrate': cmd_migrate,
    'convert': cmd_convert,
}


# 帮助条目: (命令, 参数, [描述行])
HELP = [
    ('verify', '', ['校验plist/png/gif三向一致性(数量、一一对应、重名、LICENSE)']),
    ('scan', '', ['按三维评分(完整度50%+鲜艳度30%+居中度20%)重刷全部静态图']),
    ('sheet', '<表情名>', ['铺某表情的全部帧编号对照图到桌面(红框=当前静态帧), 用于人工挑帧']),
    ('static', '<表情名> --frame N', ['把某表情的静态图换成gif里的第N帧']),
    ('move', '<表情名> --before|--after <锚点表情>', ['修改表情在plist中的位置(即面板显示顺序)']),
    ('add', '<gif路径> <表情名> [--after 某表情]', ['导入新表情gif并生成三维评分静态图, 插入plist(默认追加到末尾)']),
    ('bake', '<表情名> --frame N --first|--last [选项]', ['把gif里的第N帧烧进动画首/尾, 未来面板直接显示首/尾帧即可省掉静态图', '选项: --keep-static保留静态图, --dry-run仅预览']),
    ('migrate', '--first|--last [--dry-run]', ['批量把现有静态图(即人工定稿帧)烧进所有gif的首/尾并删静态图, 迁移到单文件方案']),
    ('convert', '<表情名|文件路径|帧序列目录> --to apng|gif|webp|frames', ['GIF/APNG/WebP互转或导出帧序列, 传表情名按bundle约定落位(apng_[名].png/webp_[名].webp), 传文件路径原地同名互转, 传帧序列目录反向合成动画', '选项: --out指定输出, --keep-source保留源文件, --lossy有损webp, --dry-run仅预览']),
]
HELP_NOTES = [
    '表情名可不带方括号(写"微笑"或"[微笑]"都行)',
    'bake/migrate/convert会重写或删除文件, 先用--dry-run预览将要发生的变更',
    '可用环境变量WY_EMOJI_DIR覆盖表情目录(测试用): WY_EMOJI_DIR=/tmp/test python3 EmojiTool.py verify',
]


def print_help():
    B, G, Y, C, D, R = (ANSI[k] for k in ('bold', 'green', 'yellow', 'cyan', 'dim', 'reset'))
    bar = C + '─' * 66 + R
    print(bar)
    print(f"{B}{C}  EmojiTool{R} {D}· WYChatView表情资源管理工具{R}")
    print(bar)
    print(f"{Y}用法{R}  {D}python3 EmojiTool.py <命令> [参数]{R}\n")
    for cmd, args, descs in HELP:
        print(f"  {B}{G}{cmd}{R}" + (f" {C}{args}{R}" if args else ''))
        for d in descs:
            print(f"    {d}")
        print()
    print(f"{Y}说明{R}")
    for n in HELP_NOTES:
        print(f"  {D}·{R} {n}")
    print(bar)


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ('-h', '--help', 'help'):
        print_help()
        return
    cmd = sys.argv[1]
    if cmd not in COMMANDS:
        die(f'未知命令 {cmd}, 运行 python3 EmojiTool.py help 查看用法')
    if not os.path.isdir(EMOJI_DIR):
        die(f'表情目录不存在: {EMOJI_DIR}')
    COMMANDS[cmd](sys.argv[2:])


if __name__ == '__main__':
    main()
