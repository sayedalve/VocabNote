"""Quiz persistence layer for VocabNote.

Owns the two quiz tables (attempts + per-question rows) and the vocabulary
read used for generation. Everything here is called on the UI thread only,
exactly like the rest of the app's DB access, using short-lived SQLite
connections so nothing is shared across threads.

Designed for the future without schema migrations:
- per-question rows (not a JSON blob) enable statistics / learning progress,
- ``extra_json`` columns on both tables absorb new fields such as difficulty
  levels or additional quiz formats.

Nothing in this module runs at application startup: ``init_quiz_tables`` is
invoked lazily the first time the Quiz page is opened.
"""

import json
import os
import sqlite3

from database import db_manager

_resolved_db_path = None
_tables_ready = False


def _resolve_db_path():
    """Locates the SQLite file used by db_manager so quiz data lives in the
    same database. Falls back to a dedicated local file if the path cannot
    be discovered (still fully offline, still per-install)."""
    global _resolved_db_path
    if _resolved_db_path:
        return _resolved_db_path

    # 1) Common module-level path constants.
    for attr in ("DB_PATH", "DB_FILE", "DATABASE_PATH", "DATABASE_FILE", "DB_NAME"):
        p = getattr(db_manager, attr, None)
        if isinstance(p, str) and p.strip():
            _resolved_db_path = p
            return p

    # 2) Ask an exposed connection factory where its main database lives.
    for attr in ("get_connection", "get_conn", "connect", "_get_connection"):
        fn = getattr(db_manager, attr, None)
        if callable(fn):
            try:
                conn = fn()
                try:
                    for _, name, filename in conn.execute("PRAGMA database_list"):
                        if name == "main" and filename:
                            _resolved_db_path = filename
                            return filename
                finally:
                    try:
                        conn.close()
                    except Exception:
                        pass
            except Exception:
                continue

    # 3) Fallback: a dedicated quiz database next to db_manager.
    fallback = os.path.join(
        os.path.dirname(os.path.abspath(db_manager.__file__)), "quiz_history.db"
    )
    _resolved_db_path = fallback
    return fallback


def _connect():
    conn = sqlite3.connect(_resolve_db_path())
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def _run(fn):
    """Runs fn(conn) inside a transaction and always closes the connection."""
    conn = _connect()
    try:
        with conn:
            return fn(conn)
    finally:
        conn.close()


def init_quiz_tables():
    """Idempotent; called lazily on first Quiz page open (zero startup cost)."""
    global _tables_ready
    if _tables_ready:
        return

    def _create(conn):
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS quiz_attempts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                created_at TEXT NOT NULL DEFAULT (datetime('now','localtime')),
                provider_name TEXT NOT NULL,
                model TEXT,
                word_source_label TEXT NOT NULL,
                volume_id INTEGER,
                question_type TEXT NOT NULL,
                num_questions INTEGER NOT NULL,
                score INTEGER NOT NULL,
                percentage REAL NOT NULL,
                time_taken_secs INTEGER NOT NULL,
                extra_json TEXT
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS quiz_questions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                attempt_id INTEGER NOT NULL
                    REFERENCES quiz_attempts(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                word TEXT NOT NULL,
                question_type TEXT NOT NULL,
                question_text TEXT NOT NULL,
                options_json TEXT NOT NULL,
                correct_index INTEGER NOT NULL,
                chosen_index INTEGER,
                is_correct INTEGER NOT NULL DEFAULT 0,
                explanation TEXT,
                extra_json TEXT
            )
            """
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_quiz_questions_attempt"
            " ON quiz_questions(attempt_id)"
        )
        conn.execute(
            "CREATE INDEX IF NOT EXISTS idx_quiz_attempts_created"
            " ON quiz_attempts(created_at)"
        )

    _run(_create)
    _tables_ready = True


def get_words_for_quiz(volume_id=None):
    """Reads the vocabulary the quiz will be generated from.

    Thin wrapper over the existing notebook query so quiz code never
    duplicates word SQL. ``volume_id=None`` means all words. Called on the
    UI thread, exactly like load_words.
    """
    return db_manager.get_all_words_dictionaries(
        search_query="",
        sort_order="ASC",
        volume_id=volume_id,
        search_all=(volume_id is None),
        favorites_only=False,
    )


def save_quiz_attempt(meta, questions):
    """Stores one completed quiz (attempt row + per-question rows).

    ``meta`` keys: provider_name, model, word_source_label, volume_id,
    question_type, num_questions, score, percentage, time_taken_secs.
    Each question dict carries: word, question_type, question, options,
    correct_index, chosen_index, is_correct, explanation.
    Returns the new attempt id.
    """
    init_quiz_tables()

    def _insert(conn):
        cur = conn.execute(
            """
            INSERT INTO quiz_attempts
                (provider_name, model, word_source_label, volume_id,
                 question_type, num_questions, score, percentage,
                 time_taken_secs, extra_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                meta.get("provider_name", ""),
                meta.get("model", ""),
                meta.get("word_source_label", ""),
                meta.get("volume_id"),
                meta.get("question_type", ""),
                int(meta.get("num_questions", 0)),
                int(meta.get("score", 0)),
                float(meta.get("percentage", 0.0)),
                int(meta.get("time_taken_secs", 0)),
                json.dumps(meta.get("extra") or {}),
            ),
        )
        attempt_id = cur.lastrowid
        conn.executemany(
            """
            INSERT INTO quiz_questions
                (attempt_id, position, word, question_type, question_text,
                 options_json, correct_index, chosen_index, is_correct,
                 explanation, extra_json)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (
                    attempt_id,
                    i,
                    q.get("word", ""),
                    q.get("question_type", ""),
                    q.get("question", ""),
                    json.dumps(q.get("options") or [], ensure_ascii=False),
                    int(q.get("correct_index", 0)),
                    q.get("chosen_index"),
                    1 if q.get("is_correct") else 0,
                    (q.get("explanation") or "").strip() or None,
                    None,
                )
                for i, q in enumerate(questions)
            ],
        )
        return attempt_id

    return _run(_insert)


def count_quiz_attempts():
    init_quiz_tables()
    return _run(
        lambda conn: conn.execute("SELECT COUNT(*) FROM quiz_attempts").fetchone()[0]
    )


def get_quiz_history(limit=50, offset=0):
    """Newest-first page of attempts (paginated so huge histories stay fast)."""
    init_quiz_tables()

    def _query(conn):
        rows = conn.execute(
            "SELECT * FROM quiz_attempts ORDER BY id DESC LIMIT ? OFFSET ?",
            (int(limit), int(offset)),
        ).fetchall()
        return [dict(r) for r in rows]

    return _run(_query)


def get_quiz_attempt_detail(attempt_id):
    """Full attempt (meta + ordered questions) for the results/review view.
    Returns None when the attempt no longer exists."""
    init_quiz_tables()

    def _query(conn):
        row = conn.execute(
            "SELECT * FROM quiz_attempts WHERE id = ?", (int(attempt_id),)
        ).fetchone()
        if row is None:
            return None
        q_rows = conn.execute(
            "SELECT * FROM quiz_questions WHERE attempt_id = ? ORDER BY position",
            (int(attempt_id),),
        ).fetchall()
        questions = []
        for q in q_rows:
            try:
                options = json.loads(q["options_json"]) or []
            except Exception:
                options = []
            questions.append(
                {
                    "word": q["word"],
                    "question_type": q["question_type"],
                    "question": q["question_text"],
                    "options": options,
                    "correct_index": q["correct_index"],
                    "chosen_index": q["chosen_index"],
                    "is_correct": bool(q["is_correct"]),
                    "explanation": q["explanation"] or "",
                }
            )
        return {"meta": dict(row), "questions": questions}

    return _run(_query)


def delete_quiz_attempt(attempt_id):
    """Deletes one attempt; its questions cascade automatically."""
    init_quiz_tables()
    _run(
        lambda conn: conn.execute(
            "DELETE FROM quiz_attempts WHERE id = ?", (int(attempt_id),)
        )
    )


def clear_quiz_history():
    """Deletes every stored quiz attempt and question."""
    init_quiz_tables()

    def _clear(conn):
        conn.execute("DELETE FROM quiz_questions")
        conn.execute("DELETE FROM quiz_attempts")

    _run(_clear)
