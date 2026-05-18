# smart_assistant

A new Flutter project.

## OpenRouter API key (AI chatbot)

**Do not commit real keys to Git.** If a key was ever pushed to GitHub, revoke it in the [OpenRouter dashboard](https://openrouter.ai/keys) and create a new one.

Each developer keeps their own key locally:

1. Copy `dart_defines.example.json` to `dart_defines.json` (this file is gitignored).
2. Put your key inside: `"OPENROUTER_API_KEY": "sk-or-v1-..."`
3. Run the app with:
   ```bash
   flutter run --dart-define-from-file=dart_defines.json
   ```
   **Android Studio Setup**: Run → Edit Configurations → **Additional run args**: `--dart-define-from-file=dart_defines.json`

---

**Note:** After cloning from GitHub, create a local `dart_defines.json` and add your OpenRouter key as described above.
