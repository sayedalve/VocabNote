"""Per-provider API key storage for VocabNote.

VocabNote historically stored a single API key under the legacy
``gemini_api_key`` setting, shared by whichever provider was selected in
Settings. The AI Quiz feature needs every provider's key remembered
permanently so the Quiz page can list all configured providers without
asking the user to retype anything.

Keys are stored in the existing settings key/value table through
``db_manager.get_setting`` / ``db_manager.save_setting`` under
``api_key::<Provider Name>`` -- no schema change, and fully backward
compatible with the legacy single-key setting, which is left untouched so
every existing code path keeps working.
"""

from database.db_manager import get_setting, save_setting

_KEY_PREFIX = "api_key::"
LEGACY_KEY_SETTING = "gemini_api_key"


def _setting_name(provider_name):
    return f"{_KEY_PREFIX}{(provider_name or '').strip()}"


def get_provider_key(provider_name):
    """Returns the saved API key for a provider, or '' when not configured."""
    if not provider_name:
        return ""
    try:
        return (get_setting(_setting_name(provider_name)) or "").strip()
    except Exception:
        return ""


def save_provider_key(provider_name, api_key):
    """Persists (or clears) the API key for a single provider."""
    if not provider_name:
        return
    save_setting(_setting_name(provider_name), (api_key or "").strip())


def migrate_legacy_key(selected_provider_name):
    """One-time, idempotent migration of the legacy shared key.

    If the legacy ``gemini_api_key`` value exists and the currently selected
    provider has no per-provider slot yet, copy it over. The legacy setting
    itself is preserved so older code paths keep reading it as before.
    """
    try:
        if not selected_provider_name:
            return
        if get_provider_key(selected_provider_name):
            return
        legacy = (get_setting(LEGACY_KEY_SETTING) or "").strip()
        if legacy:
            save_provider_key(selected_provider_name, legacy)
    except Exception:
        # A migration hiccup must never break Settings or the Quiz page.
        pass


def get_configured_providers(all_provider_names):
    """Providers (kept in preset order) that have a saved, non-empty key."""
    return [name for name in all_provider_names if get_provider_key(name)]
