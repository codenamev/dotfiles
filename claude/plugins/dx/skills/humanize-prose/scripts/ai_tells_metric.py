#!/usr/bin/env python3
"""Count AI-tell signals in a prose/markdown file.

Usage: ai_tells_metric.py <path>

Reports raw counts only. Interpretation (healthy ranges) lives in SKILL.md, so
the script stays a measuring tape, not a judge.
"""

import re
import sys

SMART_QUOTES = [chr(8220), chr(8221), chr(8216), chr(8217)]
FIRST_PERSON = ["I", "me", "Me", "my", "My"]
COLLABORATIVE = ["we", "We", "our", "Our", "us", "Us"]


# Pre-compile once; metrics() runs these on every call.
_WORD_RE = {w: re.compile(r"\b" + re.escape(w) + r"\b") for w in FIRST_PERSON + COLLABORATIVE}
# Each element may be multi-word ("the cost, the value, and the decision"); the
# space class never crosses a comma, so the three slots stay distinct.
# Known over-count: an introductory clause before a two-item "X and Y" also
# matches ("However, foo and bar" / "That said, it is fast and cheap"), scoring 1
# though it is not a triadic list. The metric is an advisory 0-2 signal, so this
# is left as acceptable noise rather than anchored out with brittle opener lists.
_TRIADIC_RE = re.compile(r"\b\w[\w ]*, \w[\w ]*,? and \w[\w ]*")


def _count_words(words, content):
    return sum(len(_WORD_RE[w].findall(content)) for w in words)


def metrics(content):
    """Return the AI-tell signal counts for a block of text."""
    return {
        "words": len(content.split()),
        "em_dashes": content.count(chr(8212)),
        "en_dashes": content.count(chr(8211)),
        "smart_quotes": sum(content.count(c) for c in SMART_QUOTES),
        "triadic": len(_TRIADIC_RE.findall(content)),
        "first_person": _count_words(FIRST_PERSON, content),
        "collaborative": _count_words(COLLABORATIVE, content),
    }


USAGE = """usage: ai_tells_metric.py <path>

Counts the mechanically-detectable AI tells in a markdown or text file: words,
em-dashes, en-dashes, smart quotes, triadic ", X, Y, and Z" lists, and
first-person / collaborative pronoun use. Counts are advisory. The judgment
tells humanize-prose also strips (abstract nouns, mechanical transitions,
closing-summary tics) are not measurable here and are left to human review."""


def main(argv):
    if any(a in ("-h", "--help") for a in argv[1:]):
        print(USAGE)
        return 0
    if len(argv) < 2:
        print(USAGE, file=sys.stderr)
        return 2
    try:
        with open(argv[1], encoding="utf-8") as f:
            content = f.read()
    except (OSError, UnicodeDecodeError) as e:
        print(f"ai_tells_metric: cannot read {argv[1]!r}: {e}", file=sys.stderr)
        return 2
    m = metrics(content)
    print(f"words: {m['words']}")
    print(f"em-dashes: {m['em_dashes']}")
    print(f"en-dashes: {m['en_dashes']}")
    print(f"smart quotes: {m['smart_quotes']}")
    print(f'triadic ", X, Y, and Z": {m["triadic"]}')
    print(f"first-person (writer-voice): {m['first_person']}")
    print(f"collaborative (we/our/us): {m['collaborative']}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
