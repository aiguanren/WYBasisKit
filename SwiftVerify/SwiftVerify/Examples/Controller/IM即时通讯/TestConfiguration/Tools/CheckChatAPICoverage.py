# -*- coding: utf-8 -*-
"""对照实际公开符号和xccov报告，列出尚未执行的聊天API方法。"""
import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from urllib.parse import unquote, urlparse

parser = argparse.ArgumentParser()
parser.add_argument('symbols', type=Path)
parser.add_argument('coverage', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
functions = defaultdict(list)
for target in json.loads(args.coverage.read_text())['targets']:
    if target['name'] != 'WYBasisKitSwift.framework': continue
    for file in target['files']:
        for function in file.get('functions', []):
            if function['name'].startswith(('closure ', 'implicit closure ')): continue
            functions[(file['path'], function['lineNumber'])].append(function)
methods = []
for symbol in json.loads(args.symbols.read_text())['symbols']:
    location = symbol.get('location', {})
    path = unquote(urlparse(location.get('uri', '')).path)
    if '/Swift/Layout/ChatView/' not in path: continue
    kind = symbol['kind']['identifier']
    if kind not in ['swift.method', 'swift.type.method', 'swift.init', 'swift.subscript']: continue
    line = location['position']['line'] + 1
    api = '.'.join(symbol['pathComponents'])
    name = api.split('(', 1)[0] + '('
    matches = [function for function in functions.get((path, line), []) if name in function['name']]
    count = sum(f['executionCount'] for f in matches)
    methods.append({'api': '.'.join(symbol['pathComponents']), 'file': path, 'line': line,
                    'status': 'executed' if count else 'notExecuted' if matches else 'noInstrumentedBody',
                    'executionCount': count})
methods.sort(key=lambda item: (item['file'], item['line'], item['api']))
report = {'counts': dict(Counter(m['status'] for m in methods)), 'methods': methods,
          'scope': '实际编译的公开方法、构造与下标；协议声明及无独立插桩的方法单列。执行到方法不代表所有分支或UI效果已通过。'}
args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(report['counts'], ensure_ascii=False))
for method in methods:
    if method['status'] == 'notExecuted': print(method['api'])
