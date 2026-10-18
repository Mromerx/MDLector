import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/translation_service.dart';
import '../../state/app_settings.dart';
import '../../state/reader_providers.dart';
import 'dialog_header.dart';

/// Opens the dialog with the meaning of a tapped [word].
Future<void> showWordMeaning(
  BuildContext context,
  WidgetRef ref,
  String word,
) {
  final target = ref.read(appSettingsProvider).get(Settings.translationTarget);
  final service = ref.read(translationServiceProvider);
  return showDialog<void>(
    context: context,
    builder: (_) => _WordMeaningDialog(word: word, target: target, service: service),
  );
}

/// Opens the dialog with the translation of a selected [text] fragment.
Future<void> showTextTranslation(
  BuildContext context,
  WidgetRef ref,
  String text,
) {
  final target = ref.read(appSettingsProvider).get(Settings.translationTarget);
  final service = ref.read(translationServiceProvider);
  return showDialog<void>(
    context: context,
    builder: (_) => _TextTranslationDialog(text: text, target: target, service: service),
  );
}

/// Meaning of a single word: its translation plus dictionary senses.
class _WordMeaningDialog extends StatefulWidget {
  const _WordMeaningDialog({
    required this.word,
    required this.target,
    required this.service,
  });

  final String word;
  final String target;
  final GoogleTranslationService service;

  @override
  State<_WordMeaningDialog> createState() => _WordMeaningDialogState();
}

class _WordMeaningDialogState extends State<_WordMeaningDialog> {
  late final Future<WordMeaning> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.lookUp(widget.word, target: widget.target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: DialogHeader(icon: Icons.menu_book_outlined, title: widget.word),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
        child: FutureBuilder<WordMeaning>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const Text('Translation failed. Check your connection.');
            }
            final meaning = snapshot.data ?? const WordMeaning();
            if (meaning.isEmpty) {
              return Text(
                'No translation found. The word may already be in '
                '${translationLanguageLabel(widget.target)} or the lookup failed.',
                style: theme.textTheme.bodyMedium,
              );
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meaning.translation != null) ...[
                    Text(
                      meaning.translation!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'in ${translationLanguageLabel(widget.target)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (meaning.senses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'MEANINGS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final sense in meaning.senses)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(sense)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
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

/// Translation of a selected fragment.
class _TextTranslationDialog extends StatefulWidget {
  const _TextTranslationDialog({
    required this.text,
    required this.target,
    required this.service,
  });

  final String text;
  final String target;
  final GoogleTranslationService service;

  @override
  State<_TextTranslationDialog> createState() => _TextTranslationDialogState();
}

class _TextTranslationDialogState extends State<_TextTranslationDialog> {
  late final Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.translateText(widget.text, target: widget.target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = widget.text.trim();
    return AlertDialog(
      title: const DialogHeader(icon: Icons.translate, title: 'Translation'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(height: 24),
              FutureBuilder<String?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Translation failed. Check your connection.',
                    );
                  }
                  final translated = snapshot.data;
                  if (translated == null || translated.isEmpty) {
                    return Text(
                      'No translation (the text may already be in '
                      '${translationLanguageLabel(widget.target)} or the '
                      'lookup failed).',
                    );
                  }
                  return Text(
                    translated,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
                  );
                },
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
