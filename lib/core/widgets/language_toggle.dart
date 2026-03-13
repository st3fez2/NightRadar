import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_copy.dart';
import '../app_language.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLanguageProvider);
    final controller = ref.read(appLanguageProvider.notifier);
    final currentLanguage = AppLanguage.fromLocale(locale);
    final copy = context.copy;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0D2C4)),
      ),
      child: PopupMenuButton<AppLanguage>(
        tooltip: copy.text(it: 'Lingua', en: 'Language'),
        initialValue: currentLanguage,
        onSelected: controller.setLanguage,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        itemBuilder: (context) {
          return AppLanguage.values
              .map(
                (language) => PopupMenuItem<AppLanguage>(
                  value: language,
                  child: Row(
                    children: [
                      Icon(
                        language == currentLanguage
                            ? Icons.check_circle_rounded
                            : Icons.language_rounded,
                        size: 18,
                        color: language == currentLanguage
                            ? const Color(0xFFE85D3F)
                            : const Color(0xFF186B5B),
                      ),
                      const SizedBox(width: 10),
                      Text(language.nativeLabel),
                    ],
                  ),
                ),
              )
              .toList();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 9 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 18,
                color: Color(0xFF18130F),
              ),
              const SizedBox(width: 8),
              Text(
                currentLanguage.shortLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18130F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
