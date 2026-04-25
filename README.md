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
**تنبيه لزميلك (Instructions for your colleague):**
عند تحميل المشروع من GitHub، لن يعمل الـ API مباشرة لأن ملف المفاتيح مخفي للحماية.
يجب عليك إنشاء ملف `dart_defines.json` ووضع مفتاح الـ API الخاص بك فيه كما هو موضح أعلاه.


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
