#!/bin/bash
# .claude/hooks/check-source.sh
#
# PostToolUse hook for Write|Edit on solvcon source files.
# Deterministic checks: ASCII-only, no trailing whitespace, vim
# modeline at EOF, Python <=79-char lines.
# Exit 2 with violations on stderr -- Claude sees the message and
# can self-correct.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
    file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
    file=$(printf '%s' "$input" \
        | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -1)
fi

[ -z "$file" ] && exit 0
[ ! -f "$file" ] && exit 0
case "$file" in
    *.py|*.cpp|*.hpp|*.c|*.h|*.cxx|*.hxx) ;;
    *) exit 0 ;;
esac

violations=""
add() { violations="${violations}  $1"$'\n'; }

# Non-ASCII bytes (Python is portable; bash byte-class is not).
nonascii_line=$(python3 - "$file" <<'PY'
import sys
with open(sys.argv[1], "rb") as f:
    for i, line in enumerate(f, 1):
        if any(b > 126 or (b < 32 and b not in (9, 10, 13)) for b in line):
            print(i)
            break
PY
)
[ -n "$nonascii_line" ] && add "$file:$nonascii_line -- non-ASCII byte -- replace with ASCII"

# Trailing whitespace.
tws_line=$(grep -nE $'[ \t]+$' "$file" | head -1 | cut -d: -f1)
[ -n "$tws_line" ] && add "$file:$tws_line -- trailing whitespace -- strip"

# Modeline at EOF (last non-empty line).
last=$(awk 'NF { l = $0 } END { print l }' "$file")
case "$file" in
    *.py)
        echo "$last" | grep -qE '^[[:space:]]*#[[:space:]]*vim:[[:space:]]+set' \
            || add "$file:EOF -- missing modeline -- append \`# vim: set ff=unix fenc=utf8 ft=python ai et sw=4 ts=4 tw=79:\`"
        ;;
    *)
        echo "$last" | grep -qE '^[[:space:]]*//[[:space:]]*vim:[[:space:]]+set' \
            || add "$file:EOF -- missing modeline -- append \`// vim: set ff=unix fenc=utf8 nobomb et sw=4 ts=4:\`"
        ;;
esac

# Python <=79 chars per line.
if [[ "$file" == *.py ]]; then
    long_line=$(awk 'length > 79 { print NR; exit }' "$file")
    [ -n "$long_line" ] && add "$file:$long_line -- line >79 chars -- wrap (PEP-8)"
fi

if [ -z "$violations" ]; then
    exit 0
fi

{
    echo "Hook violations:"
    printf '%s' "$violations"
    echo "verdict: issues found"
} >&2
exit 2
