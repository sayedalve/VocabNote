# VocabNote - Product Requirements Document (PRD)

## Core Concept
VocabNote is a personal vocabulary notebook desktop app. It is NOT a dictionary app. The primary goal is to help the user collect, organize, review, and export difficult English words encountered during daily reading or studying. AI is used strictly as a background helper to automatically fetch word details, saving the user time.

## Target Audience
A single user running Windows, looking for a clean, private, and organized way to track their personal vocabulary journey.

## Core Features
1. **Manual Entry:** Add a word manually.
2. **AI Enrichment:** Automatically fetch Meaning, Bangla meaning, English definition, IPA pronunciation, Part of speech, Example sentence, Synonyms, and Antonyms.
3. **Local Storage:** Everything is saved permanently in a local SQLite database. Works offline for saved words.
4. **Notebook Organization:** 
   - Auto-sort A to Z (and Z to A).
   - Filter by first letter.
   - Search bar for instant finding.
5. **Personalization:** Edit any fetched field, add personal notes, mark status (New, Learning, Learned), and add to favorites.
6. **Always-Visible Export:** A prominent Export button on the main UI to export lists to PDF and DOCX.
7. **Settings:** A dedicated screen to paste an AI API key (starting with Gemini), select the provider, and test the connection.
