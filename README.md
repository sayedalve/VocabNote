# 📚 VocabNote

<div align="center">

A hyper-fast, offline-first vocabulary notebook powered by Google Gemini AI.

[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![CustomTkinter](https://img.shields.io/badge/CustomTkinter-Modern_UI-1F6FEB?style=for-the-badge)](https://github.com/TomSchimansky/CustomTkinter)
[![SQLite](https://img.shields.io/badge/SQLite-Offline_Storage-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org/)
[![Gemini AI](https://img.shields.io/badge/Gemini_AI-Powered-8E75FF?style=for-the-badge)](https://ai.google.dev/)
[![Windows](https://img.shields.io/badge/Windows-Desktop_App-0078D6?style=for-the-badge&logo=windows&logoColor=white)]()

<img src="screenshot.png" alt="VocabNote Dashboard UI" width="800"/>

</div>

## 📥 Download

**[👉 Download the latest Windows executable (v1.0.0)](https://github.com/sayedalve/VocabNote/releases/latest)**

*No installation required. Just unzip and run `VocabNote.exe`. The application is fully portable and will automatically generate its local database on the first launch.*

---

## ✨ What is VocabNote?

VocabNote removes the friction from language learning by automating vocabulary enrichment. Enter a hard English word, and the built-in AI engine autonomously fetches the pronunciation, part of speech, meanings, Bangla translations, example sentences, synonyms, antonyms, and competitive exam history. 

All enriched data is stored locally via SQLite, ensuring the application remains blazing fast and fully functional offline.

## 🚀 Key Features

*   **🤖 1-Click AI Enrichment:** Type a word and press `Enter` to instantly generate comprehensive linguistic data via the `gemini-3.1-flash-lite` API.
*   **⚡ Pure Canvas Rendering Engine:** Bypasses standard Tkinter scrolling bottlenecks. The UI draws primitives directly to a single canvas, achieving buttery-smooth 60fps scrolling regardless of notebook size.
*   **🔎 Dynamic Interactive Tokens:** Synonyms and antonyms are rendered as interactive tags. Hover and click to apply a "Golden Highlight" to important words, instantly syncing to the database.
*   **📱 Real-Time UI Scaling:** A mathematical layout engine allows you to zoom in/out of the interface fluidly without pixelation on High-DPI displays.
*   **🗂 Volume Management:** Organize your vocabulary into infinite custom volumes with full CRUD capabilities.
*   **📄 Smart Export/Import:** Compile your active volume or entire notebook into clean, formatted `.docx` files for offline study or sharing.

## 🧠 Under the Hood (Architecture)

VocabNote is engineered for performance and resilience:
*   **Asynchronous Network Layer:** API calls are dispatched to background threads (`threading.Thread`) with robust `try/except` wrappers. Network drops or API timeouts will gracefully return error messages without freezing the GUI mainloop.
*   **Defensive JSON Parsing:** Custom regex-based sanitization strips rogue Markdown formatting (like ` ```json ` fences) from AI responses before parsing, preventing application crashes.
*   **"Read-Only vs. Edit" Paradigm:** Cards default to lightweight canvas text. Heavy native `CTkEntry` widgets are only spawned dynamically when a user clicks "Edit", keeping memory consumption incredibly low.

## ⚙️ Installation & Setup

### 1. Clone the repository
```bash
git clone https://github.com/sayedalve/VocabNote.git
cd VocabNote
2. Install dependencies
It is recommended to use a virtual environment. Install the required packages via pip:

Bash
pip install -r requirements.txt
3. Run the application
Bash
python src/main.py
4. Connect the AI
Launch the app and navigate to the Settings tab.

Paste your free Google AI Studio Gemini API key.

Click Test Connection. You are ready to start enriching words!

🧩 Project Structure
Plaintext
VocabNote/
├── src/
│   ├── main.py                # Application entry point & Canvas UI Engine
│   ├── api/
│   │   └── gemini.py          # LLM integration & threaded network logic
│   ├── database/
│   │   └── db_manager.py      # SQLite schema & CRUD operations
│   └── utils/
│       └── export_manager.py  # DOCX/PDF parser and generator
├── data/                      # Auto-generated SQLite database storage
├── vocab_icon.ico             # Application branding
├── requirements.txt           # Dependency manifest
└── README.md
📦 Building from Source
To compile VocabNote into a portable, branded .exe file without requiring Python on the host machine:

Bash
pip install pyinstaller
pyinstaller --noconsole --onefile --windowed --add-data "vocab_icon.ico;." --icon=vocab_icon.ico --name="VocabNote" src/main.py
🎯 Roadmap
[ ] Audio pronunciation integration

[ ] Spaced repetition flashcards

[ ] Automated daily backup mechanism

[ ] Light mode theme support

🤝 Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

📄 License
This project is licensed under the MIT License - see below for details.

Plaintext
MIT License

Copyright (c) 2026 Md Sayed (Alve)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...