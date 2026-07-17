# 📚 VocabNote

<div align="center">

**A modern, offline-first vocabulary notebook powered by Universal AI APIs.**

Store, enrich, organize, and export your vocabulary with a beautiful desktop experience built for speed.

[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![CustomTkinter](https://img.shields.io/badge/CustomTkinter-Modern_UI-1F6FEB?style=for-the-badge)](https://github.com/TomSchimansky/CustomTkinter)
[![SQLite](https://img.shields.io/badge/SQLite-Offline_Storage-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org/)
[![Universal LLM](https://img.shields.io/badge/Universal_LLM-OpenAI_Compatible-8E75FF?style=for-the-badge)](https://platform.openai.com/docs/api-reference)
[![Windows](https://img.shields.io/badge/Windows-Desktop_App-0078D6?style=for-the-badge&logo=windows&logoColor=white)]()

<img src="screenshot.png" alt="VocabNote Screenshot" width="900"/>

</div>

---

# ✨ Overview

**VocabNote** is a modern desktop vocabulary notebook that combines the speed of local storage with the power of AI.

Instead of manually searching dictionaries and writing notes, simply enter a word and let your preferred AI automatically generate rich vocabulary information including pronunciation, meanings, Bangla translation, example sentences, synonyms, antonyms, and more.

Everything is stored locally in SQLite, making the application fast, responsive, and fully usable offline after your words have been saved.

---

# 🚀 Features

### 🤖 Universal AI Support

Works with virtually every OpenAI-compatible API.

Supported providers include:

- Google AI Studio (Gemini)
- OpenRouter
- Groq
- GitHub Models
- Together AI
- DeepInfra
- Local LLMs (Ollama, LM Studio)
- Any OpenAI-compatible endpoint

Simply choose your provider, enter your API key, and start learning.

---

### 📖 AI-Powered Vocabulary Generation

Generate rich information automatically:

- IPA Pronunciation
- Parts of Speech
- English Meaning
- Bangla Meaning
- Example Sentence
- Synonyms
- Antonyms

No manual searching required.

---

### ⚡ High Performance

Designed specifically for large vocabulary collections.

Features include:

- Custom Canvas rendering engine
- Smooth scrolling
- Efficient rendering
- Lightweight memory usage
- Optimized for thousands of words

---

### 🎨 Modern Desktop UI

Built using CustomTkinter with a clean Midnight Blue interface featuring:

- Glass-inspired cards
- Rounded layouts
- High-DPI support
- Adjustable UI zoom
- Responsive rendering
- Custom scrollbar

---

### 🗂 Vocabulary Management

Organize words using unlimited custom volumes.

Features:

- Create
- Rename
- Delete
- Search
- Sort
- Edit
- Favorite words
- Personal notes

---

### 📄 Import & Export

Export your vocabulary into clean documents.

Current support:

- DOCX

Future support:

- PDF
- Markdown
- CSV

---

### 💾 Offline First

All vocabulary is stored locally using SQLite.

Benefits:

- Instant loading
- No internet required after saving
- Private local database
- Portable application

---

# 🧠 Architecture

VocabNote is designed around responsiveness and reliability.

### Background AI Requests

AI requests run in background threads, keeping the interface responsive even during slow network connections.

### Local SQLite Storage

Vocabulary is stored in SQLite for fast lookup and long-term persistence.

### Canvas-Based Rendering

Instead of relying on large numbers of native widgets, VocabNote renders most interface elements directly onto a canvas for improved performance.

### Defensive AI Response Parsing

AI responses are cleaned and validated before parsing to reduce failures caused by malformed JSON or Markdown formatting.

---

# ⚙️ Installation

## 1. Clone the repository

```bash
git clone https://github.com/sayedalve/VocabNote.git
cd VocabNote
```

## 2. Install dependencies

```bash
pip install -r requirements.txt
```

## 3. Run

```bash
python src/main.py
```

---

# 🔑 Configure AI

1. Open **Settings**
2. Select your AI provider
3. Enter your API Key
4. Click **Test Connection**
5. Start adding vocabulary

---

# 📁 Project Structure

```text
VocabNote/
│
├── src/
│   ├── main.py
│   ├── api/
│   │   └── gemini.py
│   ├── database/
│   │   └── db_manager.py
│   └── utils/
│       └── export_manager.py
│
├── data/
├── docs/
├── requirements.txt
├── vocab_icon.ico
├── screenshot.png
└── README.md
```

---

# 🛠 Build From Source

Install PyInstaller:

```bash
pip install pyinstaller
```

Build:

```bash
pyinstaller ^
--noconsole ^
--onefile ^
--windowed ^
--icon=vocab_icon.ico ^
--add-data "vocab_icon.ico;." ^
--name "VocabNote" ^
src/main.py
```

---

# 🎯 Roadmap

- [ ] Audio pronunciation
- [ ] Flashcards
- [ ] Spaced repetition
- [ ] Word statistics
- [ ] Daily learning goals
- [ ] Multiple export formats
- [ ] Automatic backup
- [ ] Light theme
- [ ] Cross-platform support (Linux/macOS)

---

# 🤝 Contributing

Contributions are welcome.

If you have ideas for improvements, bug fixes, or new features, feel free to open an issue or submit a pull request.

---

# 📄 License

Licensed under the **MIT License**.

```text
MIT License

Copyright (c) 2026 Md Sayed (Alve)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```