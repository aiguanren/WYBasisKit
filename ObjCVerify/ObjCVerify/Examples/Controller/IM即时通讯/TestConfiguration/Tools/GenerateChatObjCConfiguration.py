# -*- coding: utf-8 -*-
"""从Swift桥接源文件生成ObjC配置属性可见性清单。"""
import json
import re
from pathlib import Path

root = next(p for p in Path(__file__).resolve().parents if (p / 'WYBasisKit.xcworkspace').exists())
classes = {}
# 保留偏移和换行，排除注释、字符串内的大括号。
def code_mask(source):
    pattern = r'/\*[\s\S]*?\*/|//[^\n]*|"""[\s\S]*?"""|"(?:\\.|[^"\\])*"'
    return re.sub(pattern, lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), source)
for path in (root / 'WYBasisKit/WYBasisKit/WYBasisKit/ObjC').rglob('*.swift'):
    source = path.read_text()
    mask = code_mask(source)
    for match in re.finditer(r'@objc\((\w+)\)\s*@objcMembers\s+public class (\w+)\s*:\s*NSObject\s*\{', mask):
        start = match.end()
        depth, end = 1, start
        while depth:
            if mask[end] == '{': depth += 1
            elif mask[end] == '}': depth -= 1
            end += 1
        body = mask[start:end-1]
        properties = []
        for prop in re.finditer(r'(?m)^    (?:@objc(?:\((\w+)\))?\s+)?public (var|let) (\w+)\s*:\s*([^\n={]+)', body):
            prefix = body[:prop.start()]
            if prefix.count('{') != prefix.count('}'): continue
            properties.append((prop[1] or prop[3], prop[4].strip(), prop[2] == 'var'))
        classes[match[2]] = (match[1], properties)
seen = set()
def visit(name):
    if name in seen: return
    seen.add(name)
    for _, kind, _ in classes[name][1]:
        child = kind.rstrip('?!')
        if child in classes: visit(child)
visit('WYChatConfigObjC')
lines = ['//', '//  WYChatConfigurationCatalog.h', '//  ObjCVerify', '//', '//  Created by guanren on 2026/11/11.', '//', '', '#import <Foundation/Foundation.h>', '', '/// 由GenerateChatObjCConfiguration.py生成的配置属性清单', 'static NSDictionary<NSString *, NSArray<NSString *> *> *WYChatConfigurationCatalog(void) {', '    return @{']
for name in sorted(seen):
    runtime, props = classes[name]
    values = ', '.join('@' + json.dumps(p[0]) for p in props)
    lines.append('        @"' + runtime + '": @[' + values + '],')
lines += ['    };', '}', '']
out = Path(__file__).resolve().parents[1] / 'WYChatConfigurationCatalog.h'
out.write_text('\n'.join(lines))
print(f'{len(seen)} configuration classes, {sum(len(classes[k][1]) for k in seen)} properties')
