#!/usr/bin/env python3
"""List every speaker change in a WebVTT transcript.

Usage: python3 speaker-changes.py TRANSCRIPT.vtt
"""

import re
import sys

with open(sys.argv[1]) as f:
    content = f.read()

cues = re.findall(
    r'(\d{2}:\d{2}:\d{2}\.\d+) --> \d{2}:\d{2}:\d{2}\.\d+\n(.+?)(?=\n\n|\Z)',
    content,
    re.DOTALL,
)


def ts(t):
    h, m, s = t.split(":")
    return int(h) * 3600 + int(m) * 60 + float(s)


prev = None
for start, text in cues:
    speaker = text.split(":")[0].strip()
    if prev and speaker != prev:
        t = ts(start)
        print(f"{int(t // 60):02d}:{t % 60:05.2f}  {prev} -> {speaker}")
    prev = speaker
