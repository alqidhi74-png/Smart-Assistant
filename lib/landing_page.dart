import 'package:flutter/material.dart';
import 'constants/language.dart';
import 'login.dart';
import 'register.dart';
import 'utils/app_language_sheet.dart';

class LandingPage extends StatelessWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const LandingPage({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final activeLocale = currentLocale ?? const Locale('en');
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors:
          isDark
              ? const [Color(0x9909142B), Color(0xFF0A1124)]
              : [
                scheme.surface.withValues(alpha: 0.88),
                scheme.surface.withValues(alpha: 0.94),
              ],
    );

    final titlePrimary = isDark ? Colors.white : scheme.onSurface;
    final titleAccent = isDark ? const Color(0xFF7FE3FF) : scheme.primary;
    final subtitleColor =
        isDark
            ? Colors.white.withValues(alpha: 0.7)
            : scheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/landing_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(decoration: BoxDecoration(gradient: overlayGradient)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt,
                                      color: isDark ? Colors.white : scheme.primary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      localizations.landingBadge,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : scheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => showAppLanguageSheet(
                                  context,
                                  onLanguageChanged: onLanguageChanged,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDark ? Colors.white : scheme.primary)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          (isDark ? Colors.white : scheme.primary)
                                              .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.language,
                                        size: 16,
                                        color: isDark ? Colors.white : scheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        activeLocale.languageCode == 'ar'
                                            ? 'العربية'
                                            : 'English',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : scheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Spacer(flex: 2),
                          Builder(
                            builder: (context) {
                              final parts = localizations.landingTitle.split('\n');
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    parts.isNotEmpty ? parts.first : '',
                                    style: TextStyle(
                                      color: titlePrimary,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (parts.length > 1)
                                    Text(
                                      parts[1],
                                      style: TextStyle(
                                        color: titleAccent,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            localizations.landingSubtitle,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => Registration(
                                              onLanguageChanged: onLanguageChanged,
                                              currentLocale: activeLocale,
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: scheme.primary,
                                    foregroundColor: scheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        localizations.landingGetStarted,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => Login(
                                              onLanguageChanged: onLanguageChanged,
                                              currentLocale: activeLocale,
                                            ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        isDark ? Colors.white : scheme.primary,
                                    side: BorderSide(
                                      color:
                                          isDark
                                              ? Colors.white.withValues(alpha: 0.4)
                                              : scheme.primary.withValues(alpha: 0.55),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    localizations.landingSignIn,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
