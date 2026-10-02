#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""EmojiTool - WYChatView表情资源管理工具(运行无参数查看彩色帮助)"""
import os
import plistlib
import re
import sys
import time
from PIL import Image, ImageDraw, ImageFont

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
EMOJI_DIR = os.environ.get('WY_EMOJI_DIR') or SCRIPT_DIR
PLIST_PATH = os.path.join(os.path.dirname(EMOJI_DIR), 'WYChatViewEmoji.plist')
LICENSE_NAME = 'LICENSE.txt'
TOOL_NAME = 'EmojiTool.py'
DESKTOP = os.path.expanduser('~/Desktop')
FONT_PATH = '/System/Library/Fonts/STHeiti Medium.ttc'
W_COV, W_SAT, W_CEN = 0.5, 0.3, 0.2

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
    img = Image.open(path)
    frames, durations = [], []
    for i in range(getattr(img, 'n_frames', 1)):
        img.seek(i)
        frames.append(img.convert('RGBA'))
        durations.append(max(img.info.get('duration', 50), 20))
    return frames, durations


def load_gif_p_frames(path):
    img = Image.open(path)
    frames, durations = [], []
    for i in range(getattr(img, 'n_frames', 1)):
        img.seek(i)
        frames.append(img.copy())
        durations.append(max(img.info.get('duration', 50), 20))
    return frames, durations


def save_gif_frames(path, frames, durations):
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


def save_gif_safe(path, p_frames, durations):
    try:
        p_frames[0].save(path, format='GIF', save_all=True,
                         append_images=p_frames[1:],
                         duration=durations, loop=0,
                         transparency=255, disposal=2, optimize=False)
    except (ValueError, OSError):
        rgba_frames = [f.convert('RGBA') for f in p_frames]
        save_gif_frames(path, rgba_frames, durations)


def frame_metrics(rgba):
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
    metrics = [frame_metrics(f) for f in frames]
    ncov = norm([m[0] for m in metrics])
    nsat = norm([m[1] for m in metrics])
    ncen = norm([m[2] for m in metrics])
    scores = [W_COV * ncov[i] + W_SAT * nsat[i] + W_CEN * ncen[i] for i in range(len(frames))]
    return max(range(len(frames)), key=lambda i: scores[i])


def save_static(frame, name):
    if frame.size != (96, 96):
        frame = frame.resize((96, 96), Image.LANCZOS)
    frame.save(png_path(name), optimize=True)


def find_static_index(frames, name):
    if not os.path.exists(png_path(name)):
        return -1
    cur = Image.open(png_path(name)).convert('RGBA')
    cur_data = list(cur.getdata())
    for i, f in enumerate(frames):
        if f.size == cur.size and list(f.getdata()) == cur_data:
            return i
    return -1


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
        die('用法: sheet <表情名> | --all')
    if args[0] == '--all':
        out_dir = os.path.join(DESKTOP, '表情帧序列对照')
        os.makedirs(out_dir, exist_ok=True)
        for idx, emoji_name in enumerate(load_plist(), 1):
            path = gif_path(emoji_name)
            if not os.path.exists(path):
                continue
            _generate_sheet(path, emoji_name, os.path.join(out_dir, f'{idx:03d}-{emoji_name}.png'))
        log(f'✓ 全部帧序列对照图已生成到 {out_dir}/')
        return
    name = plain_name(args[0])
    path = gif_path(name)
    if not os.path.exists(path):
        die(f'找不到 {path}')
    out = os.path.join(DESKTOP, f'{name}-帧序列对照.png')
    _generate_sheet(path, name, out)
    log(f'✓ [{name}] 帧序列对照图已生成: {out}')


def _generate_sheet(gif_path_str, name, out_path):
    frames, _ = load_gif_frames(gif_path_str)
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
    sheet.save(out_path)


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
    name, frame, pos, keep, dry, all_mode = None, None, None, False, False, False
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
        elif a == '--all':
            all_mode = True
        else:
            name = a
        i += 1
    if pos is None:
        die('用法: bake <表情名> | --all --first|--last [--frame N] [--keep-static] [--dry-run]')
    if all_mode:
        ok = skip = fail = 0
        for emoji_name in load_plist():
            r = _bake_one(emoji_name, None, pos, keep, dry)
            if r == 'ok':
                ok += 1
            elif r == 'skip':
                skip += 1
            else:
                fail += 1
        log(f'✓ bake{"[dry-run]" if dry else "完成"}: 成功{ok}, 跳过{skip}, 失败{fail}')
        return
    if name is None or frame is None:
        die('单个bake需要--frame N指定帧号(批量--all不需要)')
    _bake_one(plain_name(name), frame, pos, keep, dry)


def _bake_one(name, frame, pos, keep, dry):
    path = gif_path(name)
    if not os.path.exists(path):
        log(f'  ✗ [{name}] 找不到 {path}')
        return 'fail'
    p_frames, durations = load_gif_p_frames(path)
    if frame is None:
        static_i = find_static_index([f.convert('RGBA') for f in p_frames], name)
        if static_i < 0 or not os.path.exists(png_path(name)):
            log(f'  跳过 [{name}] (静态图不在gif帧序列里或没有静态图)')
            return 'skip'
        frame = static_i
    if not 0 <= frame < len(p_frames):
        log(f'  ✗ [{name}] 帧号{frame}超范围(共{len(p_frames)}帧)')
        return 'fail'
    insert_at = 0 if pos == 'first' else len(p_frames)
    plan = f'[{name}] 第{frame}帧烧进{"首" if pos == "first" else "尾"}部({len(p_frames)}帧->{len(p_frames) + 1}帧), {"保留" if keep else "删除"}静态图'
    if dry:
        log(f'[dry-run] {plan}')
        return 'ok'
    chosen_p = p_frames[frame].copy()
    p_frames.insert(insert_at, chosen_p)
    durations.insert(insert_at, durations[frame])
    save_gif_safe(path, p_frames, durations)
    if not keep:
        os.remove(png_path(name))
    log(f'  ✓ {plan}')
    return 'ok'


def cmd_extract(args):
    name, frame, pos, strip, dry, all_mode = None, None, None, False, False, False
    i = 0
    while i < len(args):
        a = args[i]
        if a == '--frame':
            i += 1
            frame = int(args[i])
        elif a in ('--first', '--last'):
            pos = a[2:]
        elif a == '--strip':
            strip = True
        elif a == '--dry-run':
            dry = True
        elif a == '--all':
            all_mode = True
        else:
            name = a
        i += 1
    if name is None and not all_mode:
        die('用法: extract <表情名> | --all [--frame N | --first | --last] [--strip] [--dry-run]')
    if all_mode:
        ok = fail = 0
        for emoji_name in load_plist():
            if _extract_one(emoji_name, frame, pos, strip, dry):
                ok += 1
            else:
                fail += 1
        log(f'✓ 批量导出{"[dry-run]" if dry else "完成"}: 成功{ok}, 失败{fail}')
        return
    _extract_one(plain_name(name), frame, pos, strip, dry)


def _extract_one(name, frame, pos, strip, dry):
    path = gif_path(name)
    if not os.path.exists(path):
        log(f'  ✗ [{name}] 找不到 {path}')
        return False
    p_frames, durations = load_gif_p_frames(path)
    total = len(p_frames)
    if frame is not None:
        if not 0 <= frame < total:
            log(f'  ✗ [{name}] 帧号{frame}超范围(共{total}帧)')
            return False
    elif pos == 'first':
        frame = 0
    else:
        frame = total - 1
    if strip:
        plan = f'[{name}] 取第{frame}帧生成静态图并从gif中删掉该帧({total}帧->{total - 1}帧)'
    else:
        plan = f'[{name}] 取第{frame}帧生成静态图(gif不动, 共{total}帧)'
    if dry:
        log(f'[dry-run] {plan}')
        return True
    save_static(p_frames[frame].convert('RGBA'), name)
    if strip:
        del p_frames[frame]
        del durations[frame]
        save_gif_safe(path, p_frames, durations)
    log(f'✓ {plan}')
    return True


def cmd_sync(args):
    dry = '--dry-run' in args
    names = load_plist()
    files = os.listdir(EMOJI_DIR)
    file_names = {f[1:-5] for f in files if f.startswith('[') and f.endswith(('.gif', '.png', '.webp'))}
    new_emojis = sorted(file_names - set(names))
    missing = sorted(set(names) - file_names)
    if not new_emojis and not missing:
        log('✓ plist与表情文件完全同步, 无需处理')
        return
    if new_emojis:
        log(f'发现 {len(new_emojis)} 个新文件不在plist中:')
        for n in new_emojis:
            log(f'  + [{n}]')
        if dry:
            for n in new_emojis:
                log(f'[dry-run] 将添加 [{n}] 到plist末尾')
        else:
            for n in new_emojis:
                names.append(n)
                log(f'✓ 已添加 [{n}] 到plist末尾')
            save_plist(names)
            log(f'✓ plist已更新, 共{len(names)}个表情')
    if missing:
        log(f'发现 {len(missing)} 个plist条目没有对应文件:')
        for n in missing:
            log(f'  - [{n}]')
        if dry:
            for n in missing:
                log(f'[dry-run] 将询问是否删除 [{n}]')
        elif sys.stdin.isatty():
            to_remove = []
            for n in missing:
                ans = input(f'[{n}] 没有对应文件, 从plist中删除? [y/N(保留,自己补图)] ').strip().lower()
                if ans == 'y':
                    to_remove.append(n)
                    log(f'✓ 将删除 [{n}]')
                else:
                    log(f'  保留 [{n}] (等待补充图片)')
            if to_remove:
                names = [n for n in names if n not in to_remove]
                save_plist(names)
                log(f'✓ 已删除{len(to_remove)}个, plist剩余{len(names)}个')
        else:
            log('  提示: 非交互环境无法询问, 请补充对应文件或手动从plist中删除')
    cmd_verify([])


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
            ref = args[i]
        else:
            target = a
        i += 1
    if (target is None) == (scope is None):
        die('用法: restore <表情名> | --emojis | --all | --plist | --license | --tool [--ref 提交]')
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

    def emoji_image_paths():
        out = subprocess.check_output(['git', '-C', repo, 'ls-files', '-z', emoji_rel]).decode().split('\0')
        return [p for p in out if p
                and os.path.basename(p) not in (LICENSE_NAME, TOOL_NAME)
                and os.path.basename(p).endswith(('.png', '.gif', '.webp'))]

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
    for lbl in extras:
        path = {'LICENSE': os.path.join(emoji_rel, LICENSE_NAME),
                '表情管理工具': os.path.join(emoji_rel, TOOL_NAME),
                'plist': os.path.relpath(PLIST_PATH, repo)}[lbl]
        r = checkout([path])
        log(f'✓ 连带还原{lbl}: {len(r)}个文件' if r else f'  跳过 {lbl}')
    log('  提示: 还原会覆盖当前未提交的修改, 改到满意记得git提交')
    cmd_verify([])


HELP = [
    ('verify', '', ['校验plist/png/gif三向一致性(数量、一一对应、重名、LICENSE)']),
    ('scan', '', ['按三维评分(完整度50%+鲜艳度30%+居中度20%)重刷全部静态图']),
    ('sheet', '<表情名> | --all', ['铺某表情的全部帧编号对照图到桌面(红框=当前静态帧), 用于人工挑帧']),
    ('static', '<表情名> --frame N', ['把某表情的静态图换成gif里的第N帧']),
    ('move', '<表情名> --before|--after <锚点表情>', ['修改表情在plist中的位置(即面板显示顺序)']),
    ('add', '<gif路径> <表情名> [--after 某表情]', ['导入新表情gif并生成三维评分静态图, 插入plist(默认追加到末尾)']),
    ('bake', '<表情名> | --all --first|--last [--frame N] [--keep-static] [--dry-run]', ['把gif中的帧烧进动画首/尾: 单个需--frame N指定帧号, --all批量自动匹配静态图对应帧号', '--keep-static保留静态图(默认删除), --dry-run仅预览']),
    ('extract', '<表情名> | --all [--frame N | --first | --last] [--strip] [--dry-run]', ['从动图导出指定帧作为静态图', '--frame N指定帧号, --first取首帧, --last取末帧(默认)', '--strip同时从gif中删掉该帧(不加则gif不动)']),
    ('convert', '<表情名|文件路径|帧序列目录> | --all --to apng|gif|webp|frames', ['GIF/APNG/WebP互转或导出帧序列: 默认保持原名, --prefix加前缀, --all批量', '选项: --prefix自定义前缀, --force强制覆盖, --out指定输出, --keep-source保留源, --lossy有损webp, --dry-run预览']),
    ('sync', '[--dry-run]', ['同步plist与表情文件: 有新文件自动加入plist末尾, plist有但文件缺失的逐个询问']),
    ('restore', '<表情名> | --emojis | --all | --plist | --license | --tool', ['把资源还原到某次git提交的版本(默认HEAD)', '--ref可指定历史提交; 未提交过的新文件无法还原']),
]
HELP_NOTES = [
    '表情名可不带方括号(写"微笑"或"[微笑]"都行)',
    'bake/extract/convert会重写或删除文件, 先用--dry-run预览将要发生的变更',
    '任何命令都可加 --save [文件名] 把输出同时存一份txt到桌面',
    '不会用某条命令时: python3 EmojiTool.py example <命令名> 查看带注释的示例',
    '可用环境变量WY_EMOJI_DIR覆盖表情目录(测试用)',
]

EXAMPLES = {
    'verify': [('python3 EmojiTool.py verify', '校验三向一致性, 每次批量操作后跑一遍')],
    'scan': [('python3 EmojiTool.py scan', '全量按三维评分重刷静态图')],
    'sheet': [
        ('python3 EmojiTool.py sheet 微笑', '铺开微笑全部帧到桌面(红框=当前静态帧)'),
        ('python3 EmojiTool.py sheet --all', '批量生成全部表情的帧序列对照图到桌面文件夹'),
    ],
    'static': [('python3 EmojiTool.py static 微笑 --frame 29', '把微笑的静态图换成gif里的第29帧(帧号从sheet对照图里挑)')],
    'move': [
        ('python3 EmojiTool.py move 猪 --after 笑猫', '把[猪]移到[笑猫]后面(面板显示顺序跟着变)'),
        ('python3 EmojiTool.py move 月亮 --before 太阳', '把[月亮]移到[太阳]前面'),
    ],
    'add': [
        ('python3 EmojiTool.py add ~/Desktop/rocket.gif 火箭', '导入新表情gif, 静态图自动取三维评分最佳帧'),
        ('python3 EmojiTool.py add ~/Desktop/rocket.gif 火箭 --after 帆船', '导入并插入到[帆船]后面'),
    ],
    'bake': [
        ('python3 EmojiTool.py bake 微笑 --frame 29 --last --dry-run', '先预览: 把gif第29帧(sheet对照图里挑的帧号,从0开始)烧进尾部'),
        ('python3 EmojiTool.py bake 微笑 --frame 29 --last', '正式执行并删静态图'),
        ('python3 EmojiTool.py bake --all --last', '批量: 所有表情自动匹配静态图帧号烧进尾部'),
        ('python3 EmojiTool.py bake --all --first --keep-static', '批量烧进首部且保留静态图'),
    ],
    'extract': [
        ('python3 EmojiTool.py extract 微笑', '取gif末帧生成[微笑].png(gif不动, 帧保留在原gif中)'),
        ('python3 EmojiTool.py extract 微笑 --first', '取首帧生成静态图(gif不动)'),
        ('python3 EmojiTool.py extract 微笑 --frame 25', '取指定帧号生成静态图(gif不动)'),
        ('python3 EmojiTool.py extract --all', '批量: 所有表情取gif末帧生成静态图(gif不动)'),
        ('python3 EmojiTool.py extract 微笑 --last --strip', '取末帧生成静态图并从gif中删掉该帧'),
    ],
    'convert': [
        ('python3 EmojiTool.py convert 微笑 --to apng', 'gif转apng, 默认生成[微笑].png'),
        ('python3 EmojiTool.py convert 微笑 --to webp --dry-run', '预览转webp'),
        ('python3 EmojiTool.py convert ~/Desktop/x.gif --to apng', '独立文件原地互转'),
        ('python3 EmojiTool.py convert 微笑 --to frames', '导出编号PNG序列到桌面'),
        ('python3 EmojiTool.py convert --all --to webp --prefix my_', '批量+自定义前缀'),
    ],
    'sync': [
        ('python3 EmojiTool.py sync', '检查plist与文件差异, 新文件自动加入, 缺文件的逐个问删还是留'),
        ('python3 EmojiTool.py sync --dry-run', '预览将要同步的内容'),
    ],
    'restore': [
        ('python3 EmojiTool.py restore 微笑', '只还原微笑一个表情'),
        ('python3 EmojiTool.py restore --emojis', '仅还原所有表情图片'),
        ('python3 EmojiTool.py restore --all', '还原表情图片+交互询问是否连带其他'),
        ('python3 EmojiTool.py restore --plist', '定向还原plist'),
        ('python3 EmojiTool.py restore --tool', '还原工具自身'),
        ('python3 EmojiTool.py restore --emojis --ref HEAD~2', '回退到两次提交前'),
    ],
}


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


def cmd_example(args):
    if not args:
        die(f'用法: example <命令名>, 可选命令: {" ".join(EXAMPLES.keys())}')
    cmd = args[0]
    if cmd not in EXAMPLES:
        die(f'{cmd} 没有示例, 可选命令: {" ".join(EXAMPLES.keys())}')
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


class _Tee:
    def __init__(self, original, path):
        self.original = original
        self.file = open(path, 'w', encoding='utf-8')
    def write(self, s):
        self.original.write(s)
        self.file.write(re.sub(r'\x1b\[[0-9;]*m', '', s))
    def flush(self):
        self.original.flush()
        self.file.flush()


COMMANDS = {
    'verify': cmd_verify,
    'scan': cmd_scan,
    'sheet': cmd_sheet,
    'static': cmd_static,
    'move': cmd_move,
    'add': cmd_add,
    'bake': cmd_bake,
    'extract': cmd_extract,
    'convert': None,  # placeholder
    'sync': cmd_sync,
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
    save_name = None
    if '--save' in sys.argv:
        pos = sys.argv.index('--save')
        sys.argv.pop(pos)
        if pos < len(sys.argv) and not sys.argv[pos].startswith('-'):
            save_name = sys.argv.pop(pos)
        if not save_name:
            save_name = f'{cmd}-输出-{time.strftime("%Y%m%d-%H%M%S")}.txt'
        elif not save_name.endswith('.txt'):
            save_name += '.txt'
        save_path = os.path.join(DESKTOP, save_name)
        original_stdout = sys.stdout
        sys.stdout = _Tee(original_stdout, save_path)
    else:
        save_path, original_stdout = None, None
    try:
        COMMANDS[cmd](sys.argv[2:])
    finally:
        if save_path:
            sys.stdout = original_stdout
            log(f'✓ 输出已保存到桌面: {save_path}')


if __name__ == '__main__':
    main()
