#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""EmojiTool - WYChatView表情资源管理工具(运行无参数查看彩色帮助)"""
import os
import plistlib
import sys
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

# 提示配色: 成功绿/失败红/dry-run黄/提示灰/标题青, 按消息内容自动匹配
ANSI = {'bold': '\033[1m', 'green': '\033[32m', 'red': '\033[31m', 'yellow': '\033[33m', 'cyan': '\033[36m', 'dim': '\033[90m', 'reset': '\033[0m'}


def log(msg):
    stripped = msg.lstrip()
    if stripped.startswith('✓'):
        msg = ANSI['green'] + msg + ANSI['reset']
    elif stripped.startswith('✗'):
        msg = ANSI['red'] + msg + ANSI['reset']
    elif stripped.startswith('[dry-run]') or stripped.startswith('[') and ']' in stripped[:12]:
        msg = ANSI['yellow'] + msg + ANSI['reset']
    elif stripped.startswith('提示') or stripped.startswith('跳过'):
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
    """读出动画(gif/apng/webp)全部帧(RGBA)与每帧时长(ms)"""
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
        small = f.resize((88, 88), Image.LANCZOS)
        sheet.paste(small, (x, y), small)
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


def cmd_add(args):
    if len(args) < 2:
        die('用法: add <gif路径> <表情名> [--after 某表情]')
    src, name = args[0], plain_name(args[1])
    after = None
    if '--after' in args:
        pos = args.index('--after')
        if len(args) <= pos + 1:
            die('--after 缺参数')
        after = plain_name(args[pos + 1])
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


def cmd_unbake(args):
    name, frame, strip, dry = None, None, False, False
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--frame':
            i += 1
            if i >= len(args):
                die('--frame 缺参数')
            frame = int(args[i])
        elif a == '--strip':
            strip = True
        elif a == '--dry-run':
            dry = True
        else:
            name = a
        i += 1
    if name is None:
        die('用法: unbake <表情名> [--frame N] [--strip] [--dry-run]')
    name = plain_name(name)
    path = gif_path(name)
    if not os.path.exists(path):
        die(f'找不到 {path}')
    frames, durations = load_gif_frames(path)

    if strip:
        # 从gif中删掉烧进去的那帧(--strip)，恢复原始帧数
        if frame is None:
            die('--strip 需要配合 --frame N 指定要删的帧')
        if not 0 <= frame < len(frames):
            die(f'帧号超范围, 共{len(frames)}帧')
        plan = f'[{name}] 删除gif第{frame}帧({len(frames)}帧->{len(frames) - 1}帧) 并生成静态图'
        if dry:
            log(f'[dry-run] 将执行: {plan}')
            return
        save_static(frames[frame], name)
        del frames[frame]
        del durations[frame]
        save_gif_frames(path, frames, durations)
    else:
        # 仅从gif提取帧生成静态图(不动gif)
        frame = frame if frame is not None else len(frames) - 1
        if not 0 <= frame < len(frames):
            die(f'帧号超范围, 共{len(frames)}帧')
        plan = f'[{name}] 取gif第{frame}帧生成静态图(gif不动, 共{len(frames)}帧)'
        if dry:
            log(f'[dry-run] 将执行: {plan}')
            return
        save_static(frames[frame], name)
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
    target, to_fmt, keep, dry, lossy, out_path, plain, force, all_mode, prefix_arg = None, None, False, False, False, None, False, False, False, None
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--plain':
            plain = True
        elif a == '--force':
            force = True
        elif a == '--all':
            all_mode = True
        elif a == '--prefix':
            i += 1
            if i >= len(args):
                die('--prefix 缺参数(自定义前缀, 如 xxx_ 或 xxx)')
            prefix_arg = args[i]
        elif a == '--to':
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
    if to_fmt not in ('apng', 'gif', 'webp', 'frames') or (target is None and not all_mode):
        die('用法: convert <表情名|文件路径|帧序列目录|--all> --to apng|gif|webp|frames [--prefix 前缀] [--plain] [--force] [--lossy] [--out 路径] [--keep-source] [--dry-run]')

    # 批量模式: --all 对全部表情执行转换(apng/gif/webp), 冲突项跳过(--force覆盖)
    if all_mode:
        if to_fmt not in ('apng', 'gif', 'webp'):
            die('--all 只支持 --to apng|gif|webp')
        if to_fmt == 'apng' and prefix_arg is None and not force:
            die('批量转apng且不带前缀时, 输出[名].png会与全部静态图同名冲突, 请二选一: 加 --prefix 前缀, 或加 --force 覆盖静态图(即apng单文件方案, 静态显示将取apng首帧)')
        ok = skipped = failed = 0
        for name in load_plist():
            status = _convert_bundle_one(name, to_fmt, plain, force, keep, dry, lossy, prefix_arg, batch=True)
            if status == 'ok':
                ok += 1
            elif status == 'skip':
                skipped += 1
            else:
                failed += 1
        tail = f'批量转换{"[dry-run]" if dry else "完成"}: 成功{ok}, 跳过{skipped}, 失败{failed}'
        log(f'✓ {tail}')
        return

    # 帧序列目录模式: 编号PNG合成gif/apng
    if target is not None and os.path.isdir(target):
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
        if target is not None and os.path.isfile(target):
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

    # 独立文件模式: 原地同名互转(自定义前缀时输出为 前缀+原文件名)
    if target is not None and os.path.isfile(target):
        src_path = target
        src_ext = os.path.splitext(src_path)[1].lower()
        if to_fmt == 'gif' and src_ext == '.gif':
            die('源文件已是gif')
        if to_fmt != 'gif' and src_ext == ('.png' if to_fmt == 'apng' else '.webp'):
            die(f'源文件已是{to_fmt}')
        dst_ext = {'apng': '.png', 'gif': '.gif', 'webp': '.webp'}[to_fmt]
        stem, ext = os.path.splitext(src_path)
        dst_path = stem + dst_ext
        if prefix_arg and to_fmt != 'gif' and not plain:
            dst_path = os.path.join(os.path.dirname(stem), prefix_arg + os.path.basename(stem) + dst_ext)
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

    # bundle表情模式: 单个表情
    _convert_bundle_one(plain_name(target), to_fmt, plain, force, keep, dry, lossy, prefix_arg, batch=False)
    return


def _convert_bundle_one(name, to_fmt, plain, force, keep, dry, lossy, prefix_arg, batch):
    """bundle内单个表情的格式转换, 返回ok/skip/fail(批量模式不中断, 单次模式内部die)"""
    if to_fmt == 'gif':
        # 原名png只有在是多帧(真APNG)时才算合法源, 静态单帧png不算; 默认无前缀方案下原名产物优先
        candidates = [os.path.join(EMOJI_DIR, f'[{name}].webp'),
                      os.path.join(EMOJI_DIR, f'apng_[{name}].png'),
                      os.path.join(EMOJI_DIR, f'webp_[{name}].webp')]
        src_path = next((p for p in candidates if os.path.exists(p)), None)
        plain_png = os.path.join(EMOJI_DIR, f'[{name}].png')
        if src_path is None and os.path.exists(plain_png):
            probe = Image.open(plain_png)
            if getattr(probe, 'n_frames', 1) > 1:
                src_path = plain_png
        if src_path is None:
            # 自定义前缀产物兜底: 扫描 *[{name}].png(多帧) 与 *[{name}].webp
            import glob as _glob
            # glob里[]是字符类, 匹配字面方括号要用[[]和[]]转义
            png_pat = os.path.join(EMOJI_DIR, f'*[[]{name}[]].png')
            for p in sorted(_glob.glob(png_pat)):
                if os.path.basename(p) == f'[{name}].png':
                    continue
                if getattr(Image.open(p), 'n_frames', 1) > 1:
                    src_path = p
                    break
            if src_path is None:
                webp_pat = os.path.join(EMOJI_DIR, f'*[[]{name}[]].webp')
                webps = [p for p in sorted(_glob.glob(webp_pat))
                         if os.path.basename(p) != f'[{name}].webp']
                src_path = webps[0] if webps else None
        if src_path is None:
            if batch:
                return 'skip'
            die(f'找不到 [{name}] 的动画源(apng_[名].png/webp_[名].webp/[名].webp/多帧[名].png/自定义前缀产物)')
        dst_path = gif_path(name)
    else:
        src_path = gif_path(name)
        ext = '.png' if to_fmt == 'apng' else '.webp'
        prefix = prefix_arg
        if prefix is None:
            dst_path = os.path.join(EMOJI_DIR, f'[{name}]{ext}')
            if to_fmt == 'apng' and os.path.exists(png_path(name)):
                warn = (f'[{name}].png静态图已存在, 原名apng会覆盖它, 后果: 原静态定稿帧丢失, '
                        f'面板和气泡的静态显示将变成apng首帧(首帧不佳时面板效果差, 可restore还原)')
                if dry:
                    log(f'[dry-run] 检测到同名冲突, 正式执行时将询问是否覆盖: {warn}')
                elif force:
                    log(f'  提示: --force强制覆盖, {warn}')
                elif batch:
                    log(f'  跳过 [{name}]: {warn}')
                    return 'skip'
                elif sys.stdin.isatty():
                    print(f"{ANSI['yellow']}警告: {warn}{ANSI['reset']}")
                    if input('是否替换? [y/N] ').strip().lower() != 'y':
                        die('已取消')
                else:
                    die(f'{warn}; 非交互环境无法询问, 确认要覆盖请加 --force')
        else:
            dst_path = os.path.join(EMOJI_DIR, f'{prefix}[{name}]{ext}')
    if not os.path.exists(src_path):
        if batch:
            return 'skip'
        die(f'找不到 {src_path}')
    frames, durations = load_gif_frames(src_path)
    plan = (f'[{name}] {os.path.basename(src_path)}({len(frames)}帧) -> {os.path.basename(dst_path)}, '
            f'{"保留" if keep else "删除"}源文件')
    if dry:
        log(f'[dry-run] 将执行: {plan}')
        return 'ok'
    _write_animation(dst_path, frames, durations, to_fmt, lossy)
    if not keep:
        os.remove(src_path)
    log(f'✓ {plan}')
    if to_fmt == 'webp':
        log('  提示: 预览探测链当前为gif->apng->静态, webp通道需等代码侧支持后生效')
    else:
        log(f'  提示: 预览探测链为gif->apng->静态, {"转gif后优先走gif通道" if to_fmt == "gif" else "apng需与静态图同名共存或用--prefix区分, 代码侧识别前缀的能力待扩展"}')
    return 'ok'


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


def cmd_restore(args):
    import subprocess
    target, scope, ref = None, None, 'HEAD'
    i = 0
    while i < len(args):
        a = args[i]
        if a in ('--emojis', '--all', '--plist', '--license', '--tool'):
            scope = a[2:]
        elif a == '--ref':
            i += 1
            if i >= len(args):
                die('--ref 缺参数(commit或分支名)')
            ref = args[i]
        else:
            target = a
        i += 1
    if (target is None) == (scope is None):
        die('用法: restore <表情名> | --emojis | --all | --plist | --license | --tool [--ref 提交]')

    # git仓库根与相对路径
    try:
        repo = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'],
                                       cwd=os.path.dirname(EMOJI_DIR), stderr=subprocess.DEVNULL).decode().strip()
    except subprocess.CalledProcessError:
        die('当前不在git仓库里, 无法还原')
    if subprocess.run(['git', '-C', repo, 'rev-parse', '--verify', ref],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        die(f'git里找不到引用: {ref}')
    emoji_rel = os.path.relpath(EMOJI_DIR, repo)

    def in_ref(rel_path):
        return subprocess.run(['git', '-C', repo, 'cat-file', '-e', f'{ref}:{rel_path}'],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0

    def checkout(rel_paths):
        rel_paths = [p for p in rel_paths if in_ref(p)]
        if not rel_paths:
            return []
        subprocess.check_call(['git', '-C', repo, 'checkout', ref, '--'] + rel_paths,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return rel_paths

    # 表情图片清单 = git跟踪的表情目录文件里排除LICENSE和工具本身(-z避免中文路径被引号转义导致过滤失效)
    def emoji_image_paths():
        out = subprocess.check_output(['git', '-C', repo, 'ls-files', '-z', emoji_rel]).decode().split('\0')
        return [p for p in out if p
                and os.path.basename(p) not in (LICENSE_NAME, TOOL_NAME)
                and os.path.basename(p).endswith(('.png', '.gif', '.webp'))]

    # --all交互确认是否连带LICENSE/工具/plist(非终端环境默认不连带)
    extras = []
    if scope == 'all':
        if sys.stdin.isatty():
            for label in ('LICENSE', '表情管理工具', 'plist'):
                ans = input(f'是否连带还原{label}? [y/N] ').strip().lower()
                if ans == 'y':
                    extras.append(label)
        else:
            log('  提示: 非交互环境, --all仅还原表情图片(不含LICENSE/工具/plist)')

    if scope in ('all', 'emojis'):
        restored = checkout(emoji_image_paths())
        label = '表情图片'
    elif scope == 'plist':
        restored = checkout([os.path.relpath(PLIST_PATH, repo)])
        label = 'plist'
    elif scope == 'license':
        restored = checkout([os.path.join(emoji_rel, LICENSE_NAME)])
        label = 'LICENSE'
    elif scope == 'tool':
        restored = checkout([os.path.join(emoji_rel, TOOL_NAME)])
        label = '表情管理工具'
    else:
        name = plain_name(target)
        candidates = [os.path.join(emoji_rel, f'[{name}]{ext}') for ext in ('.png', '.gif')]
        candidates += [os.path.join(emoji_rel, f'{prefix}[{name}]{ext}')
                       for prefix, ext in (('apng_', '.png'), ('webp_', '.webp'))]
        restored = checkout(candidates)
        label = f'[{name}]'
    if not restored:
        die(f'{label} 在 {ref} 里不存在(未提交过的新文件无法还原)')
    log(f'✓ 已从 {ref} 还原{label}: {len(restored)}个文件')

    for label in extras:
        path = {'LICENSE': os.path.join(emoji_rel, LICENSE_NAME),
                '表情管理工具': os.path.join(emoji_rel, TOOL_NAME),
                'plist': os.path.relpath(PLIST_PATH, repo)}[label]
        r = checkout([path])
        log(f'✓ 连带还原{label}: {len(r)}个文件' if r else f'  跳过 {label} (在 {ref} 里不存在)')
    log('  提示: 还原会覆盖当前未提交的修改, 改到满意记得git提交, 提交了才有还原点')
    cmd_verify([])


# 帮助条目: (命令, 参数, [描述行])
HELP = [
    ('verify', '', ['校验plist/png/gif三向一致性(数量、一一对应、重名、LICENSE)']),
    ('scan', '', ['按三维评分(完整度50%+鲜艳度30%+居中度20%)重刷全部静态图']),
    ('sheet', '<表情名>', ['铺某表情的全部帧编号对照图到桌面(红框=当前静态帧), 用于人工挑帧']),
    ('static', '<表情名> --frame N', ['把某表情的静态图换成gif里的第N帧']),
    ('move', '<表情名> --before|--after <锚点表情>', ['修改表情在plist中的位置(即面板显示顺序)']),
    ('add', '<gif路径> <表情名> [--after 某表情]', ['导入新表情gif并生成三维评分静态图, 插入plist(默认追加到末尾)']),
    ('bake', '<表情名> --frame N --first|--last [选项]', ['把gif里的第N帧烧进动画首/尾, 未来面板直接显示首/尾帧即可省掉静态图', '选项: --keep-static保留静态图, --dry-run仅预览']),
    ('unbake', '<表情名> [--frame N] [--strip] [--dry-run]', ['bake/migrate的逆操作: 从gif提取帧恢复静态图', '--frame N指定取哪帧(默认末帧), --strip同时把该帧从gif中删掉(完全还原烧帧前状态)']),
    ('migrate', '--first|--last [--dry-run]', ['批量把现有静态图(即人工定稿帧)烧进所有gif的首/尾并删静态图, 迁移到单文件方案']),
    ('convert', '<表情名|文件路径|帧序列目录> | --all --to apng|gif|webp|frames', ['GIF/APNG/WebP互转或导出帧序列: 默认保持原名不加前缀(--prefix xxx_才加前缀), apng与静态图[名].png同名冲突时会警告后果并询问(批量则拦截, 需--prefix或--force), --all批量转换全部表情, 传文件路径原地互转(--prefix时输出为前缀+原文件名), 传帧序列目录反向合成动画', '选项: --prefix自定义前缀, --force强制覆盖, --out指定输出, --keep-source保留源文件, --lossy有损webp, --dry-run仅预览']),
    ('restore', '<表情名> | --emojis | --all | --plist | --license | --tool', ['把资源还原到某次git提交的版本(默认HEAD): 单个表情(png/gif及apng_/webp_变体)、--emojis仅还原表情图片(不动LICENSE/工具/plist)、--all交互询问是否连带还原LICENSE/工具/plist(非终端环境默认不连带)、其余为定向还原', '--ref可指定历史提交; 未提交过的新文件无法还原; 还原会覆盖当前未提交的修改']),
]
HELP_NOTES = [
    '表情名可不带方括号(写"微笑"或"[微笑]"都行)',
    'bake/migrate/convert会重写或删除文件, 先用--dry-run预览将要发生的变更',
    '不会用某条命令时: python3 EmojiTool.py example <命令名> 查看带注释的示例',
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


# 各命令的示例: (完整命令行, 注释说明)
EXAMPLES = {
    'verify': [
        ('python3 EmojiTool.py verify', '校验plist/png/gif三向一致性, 每次批量操作后跑一遍最安心'),
    ],
    'scan': [
        ('python3 EmojiTool.py scan', '全量按三维评分(完整+鲜艳+居中)重刷静态图, 自动换到形态最完整的帧'),
    ],
    'sheet': [
        ('python3 EmojiTool.py sheet 微笑', '铺开微笑全部帧到桌面(红框=当前静态帧), 挑好帧号后配合static换帧'),
    ],
    'static': [
        ('python3 EmojiTool.py static 微笑 --frame 29', '把微笑的静态图换成gif里的第29帧(帧号从sheet对照图里挑)'),
    ],
    'move': [
        ('python3 EmojiTool.py move 猪 --after 笑猫', '把[猪]移到[笑猫]后面(面板显示顺序跟着变)'),
        ('python3 EmojiTool.py move 月亮 --before 太阳', '把[月亮]移到[太阳]前面'),
        ('python3 EmojiTool.py move "[猪]" --after "[笑猫]"', '表情名带不带方括号都行, 两种写法等价'),
    ],
    'add': [
        ('python3 EmojiTool.py add ~/Desktop/rocket_1f680.gif 火箭', '导入新表情gif, 静态图自动取三维评分最佳帧, 追加到plist末尾'),
        ('python3 EmojiTool.py add ~/Desktop/rocket_1f680.gif 火箭 --after 帆船', '导入并插入到[帆船]后面'),
    ],
    'bake': [
        ('python3 EmojiTool.py bake 微笑 --frame 29 --last --dry-run', '先预览: 把第29帧烧进动画尾部(56帧->57帧)'),
        ('python3 EmojiTool.py bake 微笑 --frame 29 --last', '正式执行并删静态图(单文件方案, 面板显示末帧)'),
        ('python3 EmojiTool.py bake 微笑 --frame 29 --first --keep-static', '烧进首部且保留静态图(--first对应面板显示首帧)'),
    ],
    'unbake': [
        ('python3 EmojiTool.py unbake 微笑', '取微笑gif末帧生成[微笑].png(gif不动, 恢复双文件)'),
        ('python3 EmojiTool.py unbake 微笑 --frame 57', '取gif第57帧生成静态图(比如烧进去的那帧)'),
        ('python3 EmojiTool.py unbake 微笑 --frame 57 --strip', '取第57帧生成静态图并从gif中删掉该帧(完全还原烧帧前状态)'),
    ],
    'migrate': [
        ('python3 EmojiTool.py migrate --last --dry-run', '预览: 把所有表情的静态定稿帧批量烧进gif尾部'),
        ('python3 EmojiTool.py migrate --last', '正式迁移到单文件方案(烧帧+删全部静态图)'),
    ],
    'convert': [
        ('python3 EmojiTool.py convert 微笑 --to apng', 'gif转apng, 默认生成[微笑].png(与静态图同名会警告询问)'),
        ('python3 EmojiTool.py convert 微笑 --to webp --dry-run', '预览转webp(默认生成[微笑].webp, 不加前缀)'),
        ('python3 EmojiTool.py convert ~/Desktop/x.gif --to apng', '独立文件原地互转(x.gif -> x.png)'),
        ('python3 EmojiTool.py convert 微笑 --to frames', '导出编号PNG序列到桌面(微笑-帧序列/f0000.png~)'),
        ('python3 EmojiTool.py convert ~/Desktop/微笑-帧序列 --to gif --out ~/Desktop/重拼.gif', '帧序列目录反向合成gif'),
        ('python3 EmojiTool.py convert 微笑 --to webp --plain', 'webp保持原名([微笑].webp, 不加webp_前缀)'),
        ('python3 EmojiTool.py convert 微笑 --to apng --force', 'apng原名与静态图同名时跳过询问强制覆盖(即apng单文件方案)'),
        ('python3 EmojiTool.py convert --all --to apng --prefix anim_', '批量: 全部转apng并加anim_前缀(无前缀批量会被拦截, 因与全部静态图同名)'),
        ('python3 EmojiTool.py convert --all --to webp --prefix my_', '批量+自定义前缀: 生成 my_[微笑].webp 这种(前缀带不带下划线自己定)'),
        ('python3 EmojiTool.py convert ~/Desktop/aa.gif --to apng --prefix xxx_', '独立文件: aa.gif -> xxx_aa.png(xxx_自定义前缀)'),
    ],
    'restore': [
        ('python3 EmojiTool.py restore 微笑', '只还原微笑一个表情(png/gif及apng_/webp_变体)'),
        ('python3 EmojiTool.py restore --emojis', '仅还原所有表情图片, 不动LICENSE/工具/plist'),
        ('python3 EmojiTool.py restore --all', '还原表情图片, 并交互询问是否连带还原LICENSE/工具/plist'),
        ('python3 EmojiTool.py restore --plist', '定向还原plist(顺序/增删全部回退到提交版)'),
        ('python3 EmojiTool.py restore --tool', '定向还原工具自身'),
        ('python3 EmojiTool.py restore --emojis --ref HEAD~2', '回退到两次提交前的表情图片版本'),
    ],
}


def cmd_example(args):
    if not args:
        die(f'用法: example <命令名>, 可选命令: {" ".join(COMMANDS)}')
    cmd = args[0]
    if cmd not in EXAMPLES:
        die(f'{cmd} 没有示例, 可选命令: {" ".join(COMMANDS)}')
    B, G, Y, C, D, R = (ANSI[k] for k in ('bold', 'green', 'yellow', 'cyan', 'dim', 'reset'))
    entry = next(e for e in HELP if e[0] == cmd)
    usage = (cmd + ' ' + entry[1]).rstrip()
    bar = C + '─' * 66 + R
    print(bar)
    print(f"{B}{Y}示例{R} {D}·{R} {G}{usage}{R}")
    print(bar)
    cmd_w = max(len(c) for c, _ in EXAMPLES[cmd]) + 2
    for command, comment in EXAMPLES[cmd]:
        pad = ' ' * max(1, cmd_w - len(command))
        print(f"  {command}{pad}{D}# {comment}{R}")
    print(bar)


COMMANDS = {
    'verify': cmd_verify,
    'scan': cmd_scan,
    'sheet': cmd_sheet,
    'static': cmd_static,
    'move': cmd_move,
    'add': cmd_add,
    'bake': cmd_bake,
    'unbake': cmd_unbake,
    'migrate': cmd_migrate,
    'convert': cmd_convert,
    'restore': cmd_restore,
    'example': cmd_example,
}


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
