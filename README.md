# 📚 VocabNote

<div align="center">

A fast, offline first vocabulary notebook powered by Google Gemini AI.

[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![CustomTkinter](https://img.shields.io/badge/CustomTkinter-Modern_UI-1F6FEB?style=for-the-badge)](https://github.com/TomSchimansky/CustomTkinter)
[![SQLite](https://img.shields.io/badge/SQLite-Offline_Storage-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org/)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-Powered-8E75FF?style=for-the-badge)](https://ai.google.dev/)
[![Windows](https://img.shields.io/badge/Windows-Desktop_App-0078D6?style=for-the-badge&logo=windows&logoColor=white)]()

</div>

## 📥 Download

**[👉 Download the latest Windows executable v1.0.0](https://github.com/sayedalve/VocabNote/releases/tag/v1.0.0)**

No installation is required. Just unzip the folder and run `VocabNote.exe`.

## ✨ What is VocabNote

VocabNote helps you save and enrich vocabulary words instantly with AI.

It gives you pronunciation, part of speech, meanings, Bangla translation, example sentences, synonyms, antonyms, exam history, and personal notes. Everything is stored locally, so it stays fast and works offline after the data is saved.

## 🚀 Key Features

### 📖 Smart Word Enrichment
Add a word and let Gemini automatically generate:
Pronunciation
Part of speech
English meaning
Bangla meaning
Example sentence
Synonyms
Antonyms
Exam history

### 🗂 Volume Management
Organize your vocabulary into custom volumes with full create, rename, and delete support.

### 🔍 Search and Filter
Search words instantly, sort A to Z or Z to A, and filter favorites in real time.

### ⭐ Favorites and Notes
Mark important words as favorites and store your own personal notes for revision.

### 📄 Export and Import
Export your notebook to a clean DOCX file and import vocabulary back from DOCX.

### ⚡ Fast Desktop UI
Built with a custom canvas based rendering engine for smoother scrolling and better performance on large word lists.

### 💾 Offline First
All data is stored locally in SQLite for speed, privacy, and reliability.

## 🧠 Why This Project Feels Different

Most Tkinter apps become slow when the list grows. VocabNote uses a custom rendering approach instead of a heavy widget per row design. That keeps the interface responsive even with many words.

It is also designed with a modern dark UI, dynamic scaling, and background AI processing so the app stays smooth while fetching data.

## 🛠 Tech Stack

Python  
CustomTkinter  
Tkinter Canvas  
SQLite  
Google Gemini AI  
python-docx  
threading

## ⚙️ Installation

### 1. Clone the repository
```bash
git clone https://github.com/sayedalve/VocabNote.git
cd VocabNote
2. Install dependencies
pip install customtkinter requests python-docx fpdf2
3. Run the app
python src/main.py
🔑 Gemini API Setup
Open the Settings tab
Paste your Gemini API key
Click Test Connection
Start adding words
📦 Build the Windows Executable

Install PyInstaller:

pip install pyinstaller

Build:

pyinstaller --noconsole --onefile --windowed --add-data "vocab_icon.ico;." --icon=vocab_icon.ico --name="VocabNote" src/main.py

After building, keep an empty data folder beside the executable so the SQLite database can be created correctly on first launch.

🧩 Project Structure
VocabNote
├── src
│   ├── main.py
│   ├── api
│   ├── database
│   └── utils
├── data
├── vocab_icon.ico
└── README.md
🎯 Roadmap
Dark and light theme support
Audio pronunciation
Flashcards
Spaced repetition
Quiz mode
Statistics dashboard
Backup and restore
More export formats
🤝 Contributing

Pull requests and issues are welcome.

📄 License

Add a license before publishing the repository.

👨‍💻 Author

Developed by Alve