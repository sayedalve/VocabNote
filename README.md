# 📚 VocabNote

<div align="center">

**A modern, AI powered vocabulary notebook built for serious learners.**

Instantly enrich English words with pronunciation, meanings, Bangla translation, examples, synonyms, antonyms, and exam history using Google's Gemini AI, while keeping your entire vocabulary library stored locally for maximum speed and privacy.

![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![CustomTkinter](https://img.shields.io/badge/CustomTkinter-Modern_UI-1F6FEB?style=for-the-badge)
![SQLite](https://img.shields.io/badge/SQLite-Offline-003B57?style=for-the-badge&logo=sqlite)
![Gemini AI](https://img.shields.io/badge/Gemini_AI-Powered-8E75FF?style=for-the-badge)
![Platform](https://img.shields.io/badge/Windows-Desktop-0078D6?style=for-the-badge&logo=windows)

</div>

---

# ✨ Overview

Learning vocabulary should be effortless.

Instead of manually searching dictionaries, pronunciation websites, translators, and example databases, **VocabNote** enriches everything automatically with a single click.

Enter any English word and VocabNote instantly generates:

* Pronunciation (IPA)
* Part of Speech
* English Meaning
* Bangla Meaning
* Example Sentence
* Synonyms
* Antonyms
* Competitive Exam History (when available)
* Personal Notes

Everything is stored locally inside SQLite, making the application extremely fast even without an internet connection.

---

# 🚀 Why VocabNote?

Unlike traditional Tkinter applications that become sluggish with large datasets, VocabNote uses a completely custom rendering architecture optimized for desktop performance.

## ⚡ Custom Rendering Engine

Instead of creating thousands of Tkinter widgets, VocabNote renders everything directly on a Canvas.

Benefits include:

* Smooth scrolling
* Lower memory usage
* Faster rendering
* Better responsiveness
* Excellent scalability

---

## 🎯 Dynamic Zoom Engine

The interface is rendered mathematically rather than relying on fixed widget sizes.

Features include:

* Real time zoom slider
* High DPI friendly
* Crisp rendering
* No blurry scaling
* Automatic layout recalculation

---

## 🤖 AI Powered Vocabulary Enrichment

Powered by **Google Gemini AI**.

Automatically generates:

* IPA Pronunciation
* Part of Speech
* English Definition
* Bangla Meaning
* Example Sentence
* Synonyms
* Antonyms
* Exam History

Network requests run in background threads so the interface never freezes.

---

## 💾 Offline First Design

Only AI generation requires internet.

Everything else works locally.

* SQLite Database
* Instant search
* Instant filtering
* No cloud dependency
* Fast startup

---

# ✨ Features

## 📖 Vocabulary Management

* Add unlimited words
* Edit any field
* Delete entries
* Personal notes
* Star favorite words
* Duplicate detection
* AI refresh

---

## 📂 Volume Management

Organize vocabulary into multiple notebooks.

* Create volumes
* Rename volumes
* Delete volumes
* Switch instantly
* Word counter for every volume

---

## 🔍 Powerful Search

* Live search
* Search across all volumes
* Search current volume
* Sort A → Z
* Sort Z → A
* Favorite filter

---

## ⭐ Interactive Learning

Synonyms and antonyms are interactive.

Simply click any word to mark it as important.

Important words are highlighted automatically and stored permanently.

---

## 📄 Import & Export

### Export

Export:

* Current Volume
* Multiple Volumes
* Entire Notebook

to a beautifully formatted Word document.

### Import

Import vocabulary directly from DOCX while intelligently handling duplicates.

---

## ⚙ Settings

* Gemini API configuration
* API connection test
* Persistent settings
* Zoom level memory

---

# 🏗 Architecture

```
VocabNote
│
├── src/
│   ├── api/
│   ├── database/
│   ├── utils/
│   └── main.py
│
├── data/
│   └── vocab_notebook.db
│
├── vocab_icon.ico
│
└── README.md
```

---

# 🛠 Tech Stack

| Technology | Purpose |
|------------|----------|
| Python | Application |
| CustomTkinter | Modern UI |
| Tkinter Canvas | Rendering Engine |
| SQLite | Local Database |
| Google Gemini AI | Vocabulary Generation |
| python-docx | DOCX Export |
| threading | Background Processing |

---

# 📸 Screenshots

Coming soon.

---

# ⚡ Installation

## Clone the repository

```bash
git clone https://github.com/yourusername/VocabNote.git

cd VocabNote
```

---

## Install dependencies

```bash
pip install customtkinter requests python-docx fpdf2
```

---

## Run

```bash
python src/main.py
```

---

# 🔑 Gemini API Setup

1. Open **Settings**
2. Paste your Gemini API Key
3. Click **Test Connection**
4. Start adding words

You can get a free API key from Google AI Studio.

---

# 📦 Build Executable

Install PyInstaller

```bash
pip install pyinstaller
```

Build

```bash
pyinstaller ^
--onefile ^
--windowed ^
--icon=vocab_icon.ico ^
--add-data "vocab_icon.ico;." ^
--name VocabNote ^
src/main.py
```

Create an empty folder beside the executable:

```
data/
```

This allows SQLite to initialize the local database during first launch.

---

# 💡 Performance

Unlike traditional widget based applications:

✅ Canvas based rendering

✅ Responsive UI during AI requests

✅ Large vocabulary collections

✅ High DPI scaling

✅ Minimal memory usage

✅ Offline local database

---

# 🎯 Roadmap

- [ ] Dark & Light themes
- [ ] Audio pronunciation
- [ ] Flashcard mode
- [ ] Spaced repetition
- [ ] Word quiz mode
- [ ] Statistics dashboard
- [ ] Multiple AI providers
- [ ] Markdown export
- [ ] PDF export
- [ ] Backup & Restore
- [ ] Cross platform support

---

# 🤝 Contributing

Contributions are welcome.

If you have ideas, improvements, or bug fixes, feel free to open an Issue or submit a Pull Request.

---

# ⭐ Support

If you find this project useful, consider giving it a ⭐ on GitHub.

It helps the project reach more people.

---

# 📄 License

This project is licensed under the MIT License.

---

# 👨‍💻 Author

**Alve**

Built with ❤️ using Python, CustomTkinter, SQLite, and Google Gemini AI.