import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_settings.dart';
import '../widgets/dialog_header.dart';
import '../widgets/settings_tiles.dart';

/// Settings dialog. Same look as the rest of the app: [DialogHeader], the same
/// margins and a single "Close" action.
///
/// It exposes exactly the three options requested: font size, dark theme and
/// the translation target language.
class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  static const EdgeInsets _insetPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 24);
  static const EdgeInsets _contentPadding = EdgeInsets.fromLTRB(8, 0, 8, 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = MediaQuery.sizeOf(context).width - 56;
    final contentWidth = math.min(460.0, available);
    return AlertDialog(
      insetPadding: _insetPadding,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: _contentPadding,
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      title: const DialogHeader(icon: Icons.tune, title: 'Settings'),
      content: SizedBox(
        width: contentWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSection(
                title: 'Appearance',
                children: [
                  StepperSettingTile(
                    def: Settings.fontSize,
                    icon: Icons.text_fields,
                    title: 'Font size',
                    step: 2,
                    min: 12,
                    max: 48,
                    format: (value) => '${value.toStringAsFixed(0)} pt',
                  ),
                  SwitchSettingTile(
                    def: Settings.themeIsDark,
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark theme',
                  ),
                ],
              ),
              const Divider(height: 1),
              SettingsSection(
                title: 'Translation',
                children: [
                  DropdownSettingTile<String>(
                    def: Settings.translationTarget,
                    icon: Icons.translate,
                    title: 'Translate words to',
                    subtitle: 'Language the tapped word or selection is '
                        'translated into',
                    options: [
                      for (final language in kTranslationLanguages)
                        language.code,
                    ],
                    labelOf: translationLanguageLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
