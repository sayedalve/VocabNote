# Changelog

All notable changes to VocabNote are documented in this file.

## 4.0.1 — Production hardening (unreleased)

Quality-focused release: no feature, UI, or database schema changes.

### Desktop experience

- `Ctrl+F` now reliably focuses the search bar on every searchable page.
  Previously it failed on the main notebook tab whenever the capture field
  had focus (a duplicate screen-level shortcut shadowed the app-wide one);
  the app shell now owns the single `Ctrl+F` binding.
- Vocabulary cards: all text (meaning, Bangla, example, synonyms,
  antonyms, notes) is immediately selectable with a single click and drag,
  and double-clicking anywhere on a card always opens the detail view.
  Previously the card's tap handler and the text-selection gestures
  competed, so clicks were inconsistently swallowed by one or the other.
- Simplified pronunciation (“kat”) is now the default display; IPA
  (“/kæt/”) remains available under Settings → Typography.
- About page: Facebook link corrected to the full canonical URL
  (`https://facebook.com/1alve1`).

### Reliability

- Uncaught Flutter/platform errors are now logged to a size-capped rolling
  file (`%APPDATA%\VocabNote\logs\vocabnote.log`) instead of being lost.
- Quiz submission now writes the attempt, its questions/answers, and the
  final score in a single transaction — a crash mid-save can no longer leave
  a half-recorded attempt in history.
- Fixed a race where a slow word-list search/refresh could overwrite the
  results of a newer one.
- The AI enrichment status now surfaces persistent non-network failures
  (bad model, quota, malformed response) instead of failing silently.
- Quick capture from the toolbar and from the “Add word” dialog no longer
  share state, so parallel captures cannot cross-talk.

### Consistency & correctness

- The legacy 3.x importer now validates and normalizes headwords and
  notebook names with the exact same rules as the rest of the app, so
  imported rows can no longer carry lookup keys the app itself would never
  produce (previously it bypassed validation).
- All screens now format dates with one shared formatter (previously three
  different formats) and show snackbars through one shared helper.
- Help-screen search description corrected (search covers meanings,
  examples, and notes — not synonyms).

### Code health

- Deduplicated the import/export plumbing (import report, notebook
  resolve-or-create, Bangla translation mapping, field clamping) into one
  shared module used by the CSV, DOCX, and legacy importers.
- Dialog text controllers are now owned and disposed by the dialogs
  themselves.
- Removed IDE metadata, machine-local files, BOMs, and mixed line endings;
  added `.gitignore` / `.gitattributes`.
- The app package now inherits the strict workspace lint configuration.
- Added README, this changelog, and a CI workflow (analyze, format, test).

## 4.0.0

- Initial Flutter rewrite of VocabNote (from the legacy Python 3.x app):
  notebooks, quick capture, AI enrichment queue, FTS search, quizzes with
  history, import/export/backups, Windows desktop shell.
