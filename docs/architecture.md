# VocabNote - Architecture

## Technology Stack
*   **Language:** Python 3
*   **GUI Framework:** CustomTkinter (for a modern, dark-themed UI)
*   **Database:** SQLite (local database file, no server needed)
*   **API Requests:** `requests`, `google-generativeai` (for Gemini)
*   **Exporting:** `python-docx` (Word), `fpdf2` (PDF)

## Folder Structure
VocabNote/
│
├── docs/               # Planning and memory files
├── data/               # Where the local SQLite database file will live
├── src/                # All Python source code goes here
│   ├── main.py         # The file we run to start the app
│   ├── ui/             # Code for buttons, windows, and screens
│   ├── database/       # Code for saving and loading words
│   ├── api/            # Code for talking to Gemini/AI
│   └── utils/          # Code for exporting PDF/DOCX
│
└── requirements.txt    # A list of Python libraries needed
