<div align="center">

# 📚 VocabNote

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge\&logo=dart\&logoColor=white" alt="Dart"/>
<img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge\&logo=sqlite\&logoColor=white" alt="SQLite"/>
<img src="https://img.shields.io/badge/AI%20Powered-8B5CF6?style=for-the-badge" alt="AI Powered"/>
<img src="https://img.shields.io/badge/Offline%20First-10B981?style=for-the-badge" alt="Offline First"/>
<img src="https://img.shields.io/badge/Windows-0078D4?style=for-the-badge\&logo=windows\&logoColor=white" alt="Windows"/>

### A fast, offline-first AI vocabulary notebook built with Flutter

Capture a word in one keystroke, let AI fill in the card, organize your
notebooks, quiz yourself, and move your data freely.

</div>

\---

## What is VocabNote?

VocabNote is a vocabulary notebook designed to make word learning simple,
fast, and organized. Instead of switching between browser tabs to look up
meanings, pronunciations, examples, and synonyms, you enter a word directly
into VocabNote. The app asks your chosen AI provider to generate a
structured vocabulary card — meaning, IPA, part of speech, example
sentence, synonyms/antonyms, and Bangla translation — and stores it locally
for instant offline access. When you are ready to test yourself, VocabNote
turns your own notebook into multiple-choice quizzes and tracks your
attempt history.

Version 4.0 is a complete rewrite in **Flutter and Dart**, replacing the
legacy desktop app with a modern, cross-platform codebase.

## ✨ Features

* **One-keystroke capture** — add a word from the toolbar or the global
quick-add dialog (`Ctrl+N`). Words are saved locally first and enriched
in the background. New words are always displayed in title case
(`jargon` → `Jargon`).
* **AI enrichment, bring your own key** — multiple OpenAI-compatible
providers and Gemini are supported. API keys live in the OS credential
store, never in the database. The enrichment queue persists across
restarts and retries automatically with backoff while you are offline.
* **Rich vocabulary cards** — meaning, Bangla translation, IPA (full or
simplified), part of speech, example sentence, synonyms/antonyms with
"important" markers, personal notes, favorites, and text-to-speech
pronunciation.
* **Interactive cards** — double-click a card to open and edit it,
single-click a synonym/antonym to highlight it across the visible cards,
and right-click a card for a context menu (Edit Word / Copy Word /
Delete Word).
* **Offline-first storage** — everything is stored locally in SQLite (via
drift) with FTS5 full-text search and debounced-as-you-type results.
* **Quizzes** — multiple-choice quizzes (meaning / synonym / antonym /
mixed) generated on-device or by an AI provider, with a full, searchable
attempt history.
* **Data freedom** — import from the legacy 3.x database, CSV, or Word
`.docx`; export to JSON, CSV, Markdown, Anki TSV, or Word `.docx`;
snapshot backups with one-click restore staging.
* **Deep customization** — light/dark themes and a Typography \& Spacing
screen with a live card preview, plus a card zoom control on the
toolbar.
* **Keyboard friendly** — `Ctrl+N` quick add, `Ctrl+F` search, `Esc` to
clear/close, Enter to open the first match, and full keyboard traversal
of cards and menus.

## 🖥️ Supported platforms

|Platform|Status|
|-|-|
|**Windows**|Primary target — actively developed, released, and tested|
|Android / iOS / macOS / Linux / Web|Runner projects are included and the codebase is platform-agnostic, but these targets are not yet officially tested or released|

## 🚀 Getting started

### Prerequisites

* [Flutter](https://docs.flutter.dev/get-started/install) **≥ 3.44**
(stable channel) with desktop support enabled for your platform
* Dart SDK ≥ 3.6 (bundled with Flutter)
* [Melos](https://melos.invertase.dev): `dart pub global activate melos`

### Setup \& run

```sh
git clone https://github.com/sayedalve/VocabNote.git
cd VocabNote

melos bootstrap        # link workspace packages
melos run gen          # run codegen (drift, freezed, riverpod)

cd app
flutter run -d windows # or: -d macos / -d linux / an Android device id
```

On first launch, open **Settings → AI provider** to add an API key and
pick a model; capture works offline and cards fill in once a provider is
configured.

## 📦 Project structure

This is a [Melos](https://melos.invertase.dev) monorepo using Dart
**workspace resolution** (one shared dependency resolution for all
packages):

```
app/                    Flutter application shell (window, routing, tabs, telemetry)
core/ai/                Provider-agnostic AI client, adapters (OpenAI-compatible,
                        Gemini), response sanitization, timeouts
core/db/                drift (SQLite) database, DAOs, FTS5 search, text normalization
core/design\_system/     Theme tokens, shared widgets (vocab card, menus, snackbars),
                        card style scope, formatters
core/storage/           Secure API-key storage (OS credential store)
core/tts/               Text-to-speech service
features/enrich/        Quick capture + background enrichment queue
features/notebook/      Notebooks, word list, word detail
features/quiz/          Quiz setup, session, results, history
features/settings/      Appearance, typography, provider/API key settings
features/transfer/      Import/export/backup (CSV, DOCX, JSON, legacy DB)
```

Each feature package follows the same clean layering:

* `src/application` — Riverpod controllers and services
* `src/domain` — pure models and logic (never imports Flutter)
* `src/presentation` — widgets (never touches the database directly)

## 🛠️ Tech stack

|Concern|Choice|
|-|-|
|UI framework|Flutter (Material 3, custom design system)|
|State management|Riverpod (`flutter\_riverpod` + `riverpod\_annotation`)|
|Navigation|`go\_router`|
|Database|SQLite via `drift`, with FTS5 full-text search|
|Immutable models|`freezed`|
|Codegen|`build\_runner` (drift, freezed, riverpod)|
|Monorepo tooling|Melos + Dart workspace|
|Secure secrets|OS credential store (Windows Credential Manager)|

## 🔁 Development workflow

|Command|What it does|
|-|-|
|`melos bootstrap`|Link workspace packages|
|`melos run gen`|One-shot codegen in every package that uses build\_runner|
|`melos run gen:watch`|Watch-mode codegen for the package in the current directory|
|`melos run analyze`|Static analysis (fatal infos) in every package|
|`melos run format`|Verify formatting in every package|
|`melos run test`|Run tests in every package that has them|

Continuous integration runs analyze, format, and test on every push and
pull request (see `.github/workflows/ci.yaml`).

## 🏗️ Building a release

```sh
cd app

# Windows (produces build/windows/x64/runner/Release/)
flutter build windows --release

# Android
flutter build apk --release        # or: flutter build appbundle

# macOS / Linux (experimental targets)
flutter build macos --release
flutter build linux --release
```

The application icon is generated with `flutter\_launcher\_icons` from
`app/assets/icon/app\_icon.png` (`dart run flutter\_launcher\_icons` from
`app/`); a pre-generated Windows `.ico` is already committed.

## 📂 Data locations (Windows)

* **Database**: the app data directory (`%APPDATA%\\VocabNote`)
* **Backups**: `backups/` inside the data directory
* **Logs**: size-capped rolling log at
`%APPDATA%\\VocabNote\\logs\\vocabnote.log` — attach it when reporting bugs
* **API keys**: Windows Credential Manager (never on disk)

## 📄 License

&#x20;VocabNote is distributed as-is, without warranty of
any kind. Open-source licenses for bundled packages are viewable in-app
(About → View open-source licenses).

