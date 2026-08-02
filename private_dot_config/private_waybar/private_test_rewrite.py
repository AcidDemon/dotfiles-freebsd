#!/usr/bin/env python3
"""Check the niri/window rewrite table still produces an icon per app.

waybar sorts the rewrite keys (jsoncpp holds object members in a std::map) and
returns on the first match, so a badly-named key can shadow every rule after
it. That is invisible until you look at the bar. Run: python3 test_rewrite.py
"""
import io
import json
import re

CFG = '/home/acid/.config/waybar/config.jsonc'
SEP = '\x1f'

src = io.open(CFG, encoding='utf-8').read()
src = re.sub(r'^\s*//.*$', '', src, flags=re.M)
mod = json.loads(src)['niri/window']
fmt, rules = mod['format'], mod['rewrite']


def render(app_id, title):
    s = fmt.replace('{app_id}', app_id).replace('{title}', title)
    for key in sorted(rules):  # waybar's iteration order, not file order
        if re.fullmatch(key, s, re.I):
            # waybar's replacements are ECMAScript ($1), re wants \1.
            repl = re.sub(r'\$(\d)', r'\\\1', rules[key])
            return re.sub(key, repl, s, flags=re.I)
    return s


CASES = [
    ('kitty', '~/.config', '\U000f07b7'),
    ('org.wezfurlong.wezterm', 'zsh', '\U000f07b7'),
    ('firefox', 'Page — Mozilla Firefox', '\U000f0239'),
    ('org.keepassxc.KeePassXC', 'Passwords', '\U000f0306'),
    ('thunar', 'Downloads', '\U000f024b'),
    ('', '', '\U000f01c4'),  # no window focused
]

for app_id, title, glyph in CASES:
    out = render(app_id, title)
    assert glyph in out, f'{app_id or "<none>"}: no icon in {out!r}'
    assert SEP not in out, f'{app_id}: separator leaked into {out!r}'
    if title:
        assert out.endswith(title), f'{app_id}: title mangled to {out!r}'

# An app with no rule of its own: bare title, no icon, no leaked separator.
out = render('NoRuleApp', 'NORULE')
assert out == 'NORULE', out

print('ok')
