---
name: python-style-review
description: Apply solvcon's judgment-call Python style rules (naming, project conventions, test intent) to changed lines in solvcon/ or test directories. Use after editing Python sources.
tools: Read, Grep, Glob, Edit, Bash
---

# Python Style Review (solvcon)

solvcon has no separate STYLE.md; this skill plus PEP-8 are the working
reference for judgment-call review. When in doubt, match the
conventions already present in the surrounding source.

## Scope

Review only lines that appear in `git diff` against the merge base (or
`HEAD` if explicitly requested). Do NOT flag pre-existing violations on
unchanged lines -- keep changes surgical.

Deterministic checks (ASCII, trailing whitespace, vim modeline, 79-char
limit) are handled by `.claude/hooks/check-source.sh` (PostToolUse). Do
not duplicate them.

## Judgment-call rules

**Naming**
- Classes: `CamelCase`.
- Functions and variables: `snake_case`.
- Constants: `UPPER_CASE`.

**Project conventions**
- Library sources live under `solvcon/`. Unit tests live in
  `solvcon/tests/` and are named `test_*.py`; functional tests live
  under `ftests/` and are likewise named `test_*.py`.
- New `.py` modules carry the standard solvcon file header: the
  `# -*- coding: UTF-8 -*-` encoding line and the project copyright
  block, matching neighboring files in the same package.
- The runtime targets system Python plus the compiled `libmarch`
  extension; do not introduce venv/conda-specific code paths.

**Line economy**
- Prefer concise code. Flag unnecessary blank lines inside short blocks
  and needlessly spread-out code. Do not flag structural blank lines
  (between functions, logical sections).
- Never put two consecutive executable statements (separated by `;`) on
  one line. (Line width is owned by the hook; don't re-flag it here.)

**Intent**
- Tests should encode why behavior matters, not just what. If a new test
  would still pass under an obvious bug in the code it exercises,
  question it.

## Workflow

1. `git diff --name-only` against the merge base; filter to `**/*.py`.
2. Read diff hunks only.
3. Apply rules to changed lines.
4. Output each finding as
   `path:line -- rule -- (fix applied | suggestion): <description>`.
5. End with a single verdict line:
   `verdict: clean | issues found | blocking`. Use `clean` only when no
   findings remain after any hand-fixes.

## Output

- Bullets only.
- Don't paste long code excerpts; point to `file:line`.
- Be explicit when uncertain.
- Try to hand-fix formatting nits.

<!-- vim: set ff=unix fenc=utf8 et sw=4 ts=4 tw=79: -->
