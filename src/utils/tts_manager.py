import asyncio
import os
import tempfile
import threading
import time
import edge_tts
import pygame

class TTSManager:
    def __init__(self):
        pygame.mixer.init()
        self._current_task_id = 0
        self._lock = threading.Lock()

    def speak(self, word):
        with self._lock:
            self._current_task_id += 1
            task_id = self._current_task_id
        # Execute in a background thread to prevent UI freezing
        threading.Thread(target=self._speak_task, args=(word, task_id), daemon=True).start()

    def _speak_task(self, word, task_id):
        # 1. Stop any currently overlapping playback
        with self._lock:
            if pygame.mixer.music.get_busy():
                pygame.mixer.music.stop()
            try:
                pygame.mixer.music.unload()
            except AttributeError:
                pass

        # 2. Generate a secure, unique temporary file
        fd, temp_path = tempfile.mkstemp(suffix=".mp3")
        os.close(fd)

        try:
            # 3. Generate TTS audio via Edge API
            communicate = edge_tts.Communicate(word, "en-US-AriaNeural")
            asyncio.run(communicate.save(temp_path))

            # 4. Verify this thread hasn't been superseded before playing
            with self._lock:
                if self._current_task_id != task_id:
                    os.remove(temp_path)
                    return
                pygame.mixer.music.load(temp_path)
                pygame.mixer.music.play()

            # 5. Non-blocking wait for audio completion
            while True:
                with self._lock:
                    if self._current_task_id != task_id or not pygame.mixer.music.get_busy():
                        break
                time.sleep(0.1)

            # 6. Release file locks
            with self._lock:
                if self._current_task_id == task_id:
                    try:
                        pygame.mixer.music.unload()
                    except AttributeError:
                        pass
        except Exception:
            pass
        finally:
            # 7. Guaranteed cleanup (Never cache, never save)
            try:
                if os.path.exists(temp_path):
                    os.remove(temp_path)
            except Exception:
                pass