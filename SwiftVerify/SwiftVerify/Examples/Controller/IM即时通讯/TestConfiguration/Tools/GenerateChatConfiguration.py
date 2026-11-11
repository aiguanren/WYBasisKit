# -*- coding: utf-8 -*-
"""从swift-symbolgraph-extract结果生成聊天配置测试字段。"""
import argparse
import json
from pathlib import Path
from collections import defaultdict

parser = argparse.ArgumentParser()
parser.add_argument('symbols', type=Path)
args = parser.parse_args()
symbols = json.loads(args.symbols.read_text())['symbols']
structs = {s['pathComponents'][0] for s in symbols if s['kind']['identifier'] == 'swift.struct' and len(s['pathComponents']) == 1}
enums = {s['pathComponents'][0] for s in symbols if s['kind']['identifier'] == 'swift.enum' and len(s['pathComponents']) == 1}
fields = defaultdict(list)
cases = defaultdict(list)
for item in symbols:
    path = item['pathComponents']
    if item['kind']['identifier'] == 'swift.property' and len(path) == 2 and item.get('declarationFragments', [{}])[0].get('spelling') == 'var':
        fields[path[0]].append(item)
    if item['kind']['identifier'] == 'swift.enum.case' and len(path) == 2:
        cases[path[0]].append(path[1])

def quote(text): return json.dumps(text, ensure_ascii=False)
def split_tuple(text):
    result, depth, start = [], 0, 0
    for index, char in enumerate(text):
        if char in '([<': depth += 1
        if char in ')]>': depth -= 1
        if char == ',' and depth == 0: result.append(text[start:index]); start = index + 1
    result.append(text[start:])
    return [piece.strip() for piece in result]

roots, leaves, expanded = [], [], set()
def expand_tuple(path, name, kind):
    if kind.startswith('(') and kind.endswith(')') and '->' not in kind:
        for index, part in enumerate(split_tuple(kind[1:-1])):
            if ': ' in part: label, subtype = part.split(': ', 1)
            else: label, subtype = str(index), part
            expand_tuple(path + '.' + label, name + ' / ' + label, subtype)
    else: leaves.append((path, name, kind))

def walk(name, prefix, visited):
    expanded.add(name)
    for symbol in sorted(fields[name], key=lambda s: s['pathComponents'][-1]):
        declaration = ''.join(fragment['spelling'] for fragment in symbol['declarationFragments'])
        kind = declaration.split(': ', 1)[-1]
        path = prefix + symbol['pathComponents'][-1]
        doc = '\n'.join(line['text'] for line in symbol.get('docComment', {}).get('lines', [])) or path
        if kind in structs and kind not in visited: walk(kind, path + '.', visited | {kind})
        else:
            roots.append(path)
            expand_tuple(path, doc, kind)
walk('WYChatConfig', '', {'WYChatConfig'})

raw_ui = {
    'UIView.ContentMode': list(range(13)),
    'UIKeyboardType': list(range(12)),
    'UIReturnKeyType': list(range(12)),
    'NSLineBreakMode': list(range(6)),
    'UICollectionView.ScrollDirection': [0, 1],
    'UIModalPresentationStyle': [-2, -1, *range(8)],
    'UIScrollView.KeyboardDismissMode': [0, 1, 2],
    'UIRectCorner': None,
    'UIDataDetectorTypes': None
}

def related(path):
    if path.startswith('recording'): return '录音'
    if path.startswith('media'): return '媒体'
    if path.startswith('emoji'): return '表情'
    if path.startswith('contentOverrides'): return '全部消息测高与复用'
    return '消息事件与输入面板'

def build(path, name, kind):
    lead = quote(path) + ', ' + quote(name)
    get = 'get: { $0.' + path + ' }'
    setter = 'set: { $0.' + path + ' = $1 }'
    if kind == 'Bool': return '.boolean(' + lead + ', ' + get + ', ' + setter + ')'
    if kind == 'Int': return '.integer(' + lead + ', ' + get + ', ' + setter + ')'
    if kind in ['CGFloat', 'Float', 'Double', 'TimeInterval']:
        return '.scalar(' + lead + ', ' + quote(kind) + ', get: { Double($0.' + path + ') }, set: { $0.' + path + ' = ' + kind + '($1) })'
    methods = {'[UIColor]': 'colors', 'CGPoint?': 'optionalPoint', 'URL': 'directory', 'WYSourceBundle?': 'sourceBundle', '[AnyClass]': 'classes'}
    if kind in methods: return '.' + methods[kind] + '(' + lead + ', ' + get + ', ' + setter + ')'
    if kind in ['String', 'String?']:
        method = 'optionalString' if kind.endswith('?') else 'string'
        return '.' + method + '(' + lead + ', ' + get + ', ' + setter + ')'
    if kind in ['UIColor', 'UIColor?', 'UIImage', 'UIImage?']:
        method = 'color' if kind.startswith('UIColor') else 'image'
        clear = ', clear: { $0.' + path + ' = nil }' if kind.endswith('?') else ''
        return '.' + method + '(' + lead + ', ' + get + ', ' + setter + clear + ')'
    if kind == 'UIFont': return '.font(' + lead + ', ' + get + ', ' + setter + ')'
    vector = {'CGSize': ['width', 'height'], 'CGPoint': ['x', 'y'], 'UIEdgeInsets': ['top', 'left', 'bottom', 'right']}
    if kind in vector:
        labels = vector[kind]
        read = ', '.join('Double($0.' + path + '.' + label + ')' for label in labels)
        value = kind + '(' + ', '.join(label + ': CGFloat($1[' + str(index) + '])' for index, label in enumerate(labels)) + ')'
        return '.vector(' + lead + ', ' + quote(kind) + ', labels: ' + json.dumps(labels) + ', get: { [' + read + '] }, set: { $0.' + path + ' = ' + value + ' })'
    if kind in enums or kind in raw_ui:
        values = raw_ui.get(kind)
        if kind in enums:
            options = '[' + ', '.join('String(' + kind + '.' + case + '.rawValue) + ' + quote(' ' + case) for case in sorted(cases[kind])) + '].joined(separator: "\\n")'
        else: options = quote('使用' + kind + '的rawValue')
        allowed = ', allowed: ' + json.dumps(values) if values is not None else ''
        return '.raw(' + lead + ', options: ' + options + allowed + ', ' + get + ', ' + setter + ')'
    if kind in ['[CGFloat]', '[Float]']:
        subtype = kind[1:-1]
        return '.numbers(' + lead + ', ' + quote(kind) + ', get: { $0.' + path + '.map { Double($0) } }, set: { $0.' + path + ' = $1.map { ' + subtype + '($0) } })'
    if kind.startswith('[') and kind.endswith(']') and kind[1:-1] in enums:
        return '.rawArray(' + lead + ', options: ' + quote('用逗号分隔' + kind[1:-1] + '的rawValue') + ', ' + get + ', ' + setter + ')'
    if kind in ['[String]', '[[String : String]]', '[String : Any]']:
        return '.json(' + lead + ', ' + get + ', ' + setter + ')'
    return '.special(' + lead + ', ' + quote(kind) + ', related: ' + quote(related(path)) + ', ' + get + ', ' + setter + ')'

output = Path(__file__).resolve().parent.parent / 'WYChatTestConfigurationFields.swift'
text = '//\n//  WYChatTestConfigurationFields.swift\n//  SwiftVerify\n//\n//  Created by guanren on 2026/11/10.\n//\n\nimport UIKit\n\n/// 编译模块对应的聊天配置字段目录\n@MainActor\nenum WYChatTestConfigurationFields {\n    static let defaults = WYChatConfig()\n    static let rootPaths: [String] = [\n'
text += ''.join('        ' + quote(path) + ',\n' for path in sorted(roots))
text += '    ]\n    static let expandedTypes: Set<String> = ' + json.dumps(sorted(expanded)) + '\n    static let all: [WYChatTestConfigurationField] = makeFields()\n    private static func makeFields() -> [WYChatTestConfigurationField] {\n        var result: [WYChatTestConfigurationField] = []\n'
entries = [build(path, name, kind) for path, name, kind in sorted(leaves)]
chunks = [entries[index:index + 32] for index in range(0, len(entries), 32)]
for index in range(len(chunks)): text += '        result += group' + str(index) + '()\n'
text += '        return result\n    }\n'
for index, chunk in enumerate(chunks):
    text += '    private static func group' + str(index) + '() -> [WYChatTestConfigurationField] { [\n'
    text += ''.join('        ' + item + ',\n' for item in chunk)
    text += '    ] }\n'
text += '}\n'
output.write_text(text)
print('generated', len(roots), 'root leaves,', len(leaves), 'editor fields')
