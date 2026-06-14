---
name: cpp-style-review
description: Apply solvcon/libmarch judgment-call C++ style rules (m_ prefix, function-body placement, pybind11 binding split, const_cast) to changed lines in libmarch/. Use after editing C++ sources.
tools: Read, Grep, Glob, Edit, Bash
---

# C++ Style Review (solvcon / libmarch)

solvcon's C++ lives under `libmarch/` (`libmarch/src`,
`libmarch/include/march`, with gtests in `libmarch/tests/gtest`). There
is no separate STYLE.md; this skill plus the conventions already in the
source are the working reference. When in doubt, match the surrounding
code.

## Scope

Review only lines that appear in `git diff` against the merge base (or
`HEAD` if explicitly requested). Do NOT flag pre-existing violations on
unchanged lines -- keep changes surgical.

Deterministic checks (ASCII bytes, trailing whitespace, vim modeline at
EOF) are handled by `.claude/hooks/check-source.sh` (PostToolUse). Do
not duplicate them. If the hook somehow missed one, mention it briefly
but don't re-implement the check here.

## Judgment-call rules

**Naming**
- Classes / structs: `CamelCase`.
- Functions and variables: `snake_case`.
- Member variables: `m_snake_case`. libmarch uses the `m_` prefix
  pervasively -- flag any class member without it.
- Constants: `UPPER_CASE`, or `snake_case` when interoping with foreign
  code (the rationale should be evident from context; question it when
  it isn't).
- Type aliases: `snake_case_t` or `snake_case_type`.

**Type casting**
- `const_cast` is suspect. If introduced in the diff, ask whether it can
  be removed.

**Function-body placement**
- Move non-accessor function bodies outside the class declaration when
  the body is more than ~2-3x the size of an accessor.
- Keep short accessors inline.
- Trivial bodies (single `return`, single assignment) as one-liners.

**Line economy**
- Prefer concise code. Flag unnecessary blank lines inside short blocks
  and needlessly spread-out code. Do not flag structural blank lines
  (between functions, logical sections, access specifiers).
- Never trade line-width conformance for fewer lines, and never put two
  consecutive executable statements (separated by `;`) on one line. A
  single-statement inline accessor body is one statement, not two, and
  stays the preferred form.

**pybind11**
- libmarch binds to Python via pybind11 (`libmarch/src/python`,
  `libmarch/include/march/python`). Split constructors from other
  bindings (methods, properties) into distinct binding sections.

## Workflow

1. `git diff --name-only` against the merge base; filter to
   `libmarch/**/*.{cpp,hpp,c,h}` (including `libmarch/tests/gtest`).
2. For each file, read only the diff hunks (use `git diff` output).
3. Apply the rules above to changed lines.
4. Output each finding as `path:line -- rule -- (fix applied |
   suggestion): <description>`.
5. End with a single verdict line:
   `verdict: clean | issues found | blocking`. Use `clean` only when no
   findings remain after any hand-fixes.

## Output

- Bullets only. No prose summaries.
- Don't paste long code excerpts; point to `file:line`.
- Be explicit when uncertain ("not sure whether X is intentional --
  please confirm").
- Try to hand-fix small, unambiguous nits; leave broad reformatting to
  the author.

<!-- vim: set ff=unix fenc=utf8 et sw=4 ts=4 tw=79: -->
