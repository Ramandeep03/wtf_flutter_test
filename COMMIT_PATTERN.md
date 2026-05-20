# Commit Pattern

## Format

```
<type>(<scope>): <subject> [AI?]
```

- **type** — one of: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`, `perf`, `build`, `ci`.
- **scope** — area touched: `scaffold`, `backend`, `auth`, `chat`, `call`, `scheduler`, `sessions`, `notifications`, `shared`, `guru`, `trainer`, `docs`, `ci`, etc.
- **subject** — imperative, ≤ 72 chars, no trailing period.
- **`[AI]` suffix** — REQUIRED if any AI tool wrote or meaningfully modified the code in this commit. Optional `[AI-partial]` if AI only assisted.

## `[AI]` rule

Every commit tagged `[AI]` MUST have a matching entry in `AI_LEDGER.md` with:
- the tool used,
- the intent,
- the prompt (≤ 2 lines, paraphrased ok),
- whether the output was used (yes / partial / no),
- the commit sha (filled in after committing).

No `[AI]` tag → no ledger entry needed.
`[AI]` tag without a ledger entry → invalid commit, amend or add the entry.

## Examples

```
chore(scaffold): init monorepo backend-first architecture [AI]
feat(backend): add /auth/login with Firebase Admin verify [AI]
fix(guru): correct ApiLoading state in scheduler bloc
docs(architecture): clarify 100ms token flow [AI-partial]
test(trainer): cover requests bloc happy path
```

## Body / footer (optional)

Use the body to explain *why* when it's not obvious from the subject. Reference ledger entries by number when helpful: `Refs AI_LEDGER #4`.
