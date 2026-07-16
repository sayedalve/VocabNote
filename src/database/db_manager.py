import sqlite3
import os
from datetime import datetime

DB_PATH = os.path.join("data", "vocab_notebook.db")
MAX_WORDS_PER_VOLUME = 500


def init_db():
    # Automatically create the 'data' folder if missing
    os.makedirs("data", exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute('''CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS volumes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, created_at TEXT)''')

    cursor.execute("SELECT COUNT(*) FROM volumes")
    if cursor.fetchone()[0] == 0:
        cursor.execute(
            "INSERT INTO volumes (name, created_at) VALUES (?, ?)",
            ("Volume 1", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        )

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT UNIQUE NOT NULL,
        meaning TEXT,
        bangla_meaning TEXT,
        english_definition TEXT,
        ipa TEXT,
        part_of_speech TEXT,
        example_sentence TEXT,
        synonyms TEXT,
        antonyms TEXT,
        status TEXT DEFAULT 'New',
        is_favorite INTEGER DEFAULT 0,
        notes TEXT DEFAULT '',
        date_added TEXT
    )
    ''')
    conn.commit()

    # Safe migrations
    try:
        cursor.execute("ALTER TABLE words ADD COLUMN important_synonyms TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE words ADD COLUMN important_antonyms TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE words ADD COLUMN volume_id INTEGER DEFAULT 1")
        cursor.execute("UPDATE words SET volume_id = 1 WHERE volume_id IS NULL")
    except sqlite3.OperationalError:
        pass

    try:
        cursor.execute("ALTER TABLE words ADD COLUMN exam_history TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass

    conn.commit()
    conn.close()


def get_setting(key):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT value FROM settings WHERE key = ?", (key,))
        result = cursor.fetchone()
        return result[0] if result else None
    finally:
        conn.close()


def save_setting(key, value):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
            (key, value)
        )
        conn.commit()
    finally:
        conn.close()


def get_all_volumes():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    try:
        cursor.execute('''
            SELECT v.id, v.name, COUNT(w.id) as word_count
            FROM volumes v
            LEFT JOIN words w ON v.id = w.volume_id
            GROUP BY v.id
            ORDER BY v.id ASC
        ''')
        return [dict(row) for row in cursor.fetchall()]
    finally:
        conn.close()


def create_volume(name):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO volumes (name, created_at) VALUES (?, ?)",
            (name, datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()


def rename_volume(vol_id, new_name):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("UPDATE volumes SET name = ? WHERE id = ?", (new_name, vol_id))
        conn.commit()
        return True
    finally:
        conn.close()


def delete_volume(vol_id):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT COUNT(*) FROM volumes")
        total_volumes = cursor.fetchone()[0]

        if total_volumes <= 1:
            return False, "Cannot delete the last remaining volume."

        cursor.execute("SELECT COUNT(*) FROM words WHERE volume_id = ?", (vol_id,))
        if cursor.fetchone()[0] > 0:
            return False, "Cannot delete a volume that contains words."

        cursor.execute("DELETE FROM volumes WHERE id = ?", (vol_id,))
        conn.commit()
        return True, "Volume deleted."
    finally:
        conn.close()


def get_available_volume_for_new_word(preferred_vol_id=None):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT COUNT(*) FROM volumes")
        volume_count = cursor.fetchone()[0]

        if volume_count == 0:
            cursor.execute(
                "INSERT INTO volumes (name, created_at) VALUES (?, ?)",
                ("Volume 1", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
            )
            conn.commit()
            return cursor.lastrowid

        if preferred_vol_id:
            cursor.execute("SELECT COUNT(*) FROM words WHERE volume_id = ?", (preferred_vol_id,))
            if cursor.fetchone()[0] < MAX_WORDS_PER_VOLUME:
                return preferred_vol_id

        cursor.execute("SELECT id FROM volumes ORDER BY id DESC LIMIT 1")
        latest_row = cursor.fetchone()

        if latest_row:
            latest_vol_id = latest_row[0]
            cursor.execute("SELECT COUNT(*) FROM words WHERE volume_id = ?", (latest_vol_id,))
            if cursor.fetchone()[0] < MAX_WORDS_PER_VOLUME:
                return latest_vol_id

        cursor.execute("SELECT COUNT(*) FROM volumes")
        vol_count = cursor.fetchone()[0]
        cursor.execute(
            "INSERT INTO volumes (name, created_at) VALUES (?, ?)",
            (f"Volume {vol_count + 1}", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        )
        conn.commit()
        return cursor.lastrowid
    finally:
        conn.close()


def save_word_to_db(word, ai_data, current_vol_id=None):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    target_vol_id = get_available_volume_for_new_word(current_vol_id)
    try:
        cursor.execute('''
        INSERT INTO words (
            word, meaning, bangla_meaning, english_definition, ipa, part_of_speech,
            example_sentence, synonyms, antonyms, date_added, volume_id, exam_history
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            word.lower(),
            ai_data.get("meaning", ""),
            ai_data.get("bangla_meaning", ""),
            ai_data.get("english_definition", ""),
            ai_data.get("ipa", ""),
            ai_data.get("part_of_speech", ""),
            ai_data.get("example_sentence", ""),
            ai_data.get("synonyms", ""),
            ai_data.get("antonyms", ""),
            datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            target_vol_id,
            ai_data.get("exam_history", "")
        ))
        conn.commit()
        return True, f"'{word}' saved permanently!"
    except sqlite3.IntegrityError:
        return False, f"'{word}' is already in your notebook!"
    except Exception as e:
        return False, f"Database error: {str(e)}"
    finally:
        conn.close()


def get_all_words_dictionaries(search_query="", sort_order="ASC", volume_id=None, search_all=False, favorites_only=False):
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    try:
        order = "DESC" if sort_order.upper() == "DESC" else "ASC"
        query_base = "SELECT * FROM words"
        params = []
        conditions = []

        if search_query:
            conditions.append("word LIKE ?")
            params.append(f"%{search_query.lower()}%")

        if volume_id and not search_all:
            if isinstance(volume_id, list):
                placeholders = ",".join("?" for _ in volume_id)
                conditions.append(f"volume_id IN ({placeholders})")
                params.extend(volume_id)
            else:
                conditions.append("volume_id = ?")
                params.append(volume_id)

        if favorites_only:
            conditions.append("is_favorite = 1")

        if conditions:
            query_base += " WHERE " + " AND ".join(conditions)

        query_base += f" ORDER BY word {order}"

        cursor.execute(query_base, tuple(params))
        return [dict(row) for row in cursor.fetchall()]
    except Exception:
        return []
    finally:
        conn.close()


def check_word_exists(word):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT 1 FROM words WHERE word = ?", (word.lower(),))
        return cursor.fetchone() is not None
    finally:
        conn.close()


def update_single_field(word, field_name, new_value):
    allowed_fields = [
        'meaning', 'bangla_meaning', 'english_definition', 'ipa', 'part_of_speech',
        'example_sentence', 'synonyms', 'antonyms', 'important_synonyms',
        'important_antonyms', 'notes', 'is_favorite', 'exam_history'
    ]
    if field_name not in allowed_fields:
        return False

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute(
            f"UPDATE words SET {field_name} = ? WHERE word = ?",
            (new_value, word.lower())
        )
        conn.commit()
        return True
    except Exception:
        return False
    finally:
        conn.close()


def delete_word(word):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM words WHERE word = ?", (word.lower(),))
        conn.commit()
        return True
    except Exception:
        return False
    finally:
        conn.close()