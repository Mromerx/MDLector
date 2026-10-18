import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_settings.dart';
import '../../state/reader_providers.dart';
import '../widgets/markdown_content.dart';
import 'settings_panel.dart';

/// Main screen: app bar with the file actions and the lazy Markdown reader.
class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reader = ref.watch(readerProvider);
    final fontSize =
        ref.watch(appSettingsProvider.select((s) => s.get(Settings.fontSize)));

    return Scaffold(
      appBar: AppBar(
        title: _Title(fileName: reader.fileName),
        actions: [
          IconButton(
            tooltip: 'Open file',
            icon: const Icon(Icons.folder_open),
            onPressed: () => ref.read(readerProvider.notifier).pickAndOpen(),
          ),
          if (reader.hasDocument)
            IconButton(
              tooltip: 'Close document',
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(readerProvider.notifier).close(),
            ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const SettingsPanel(),
            ),
          ),
        ],
      ),
      body: switch (reader.status) {
        ReaderStatus.empty => _Welcome(
            onOpen: () => ref.read(readerProvider.notifier).pickAndOpen(),
          ),
        ReaderStatus.loading => const Center(child: CircularProgressIndicator()),
        ReaderStatus.error => _ErrorPanel(
            message: reader.errorMessage,
            onRetry: () => ref.read(readerProvider.notifier).pickAndOpen(),
            onClose: () => ref.read(readerProvider.notifier).close(),
          ),
        ReaderStatus.ready => MarkdownContent(
            blocks: reader.blocks,
            fontSize: fontSize,
          ),
      },
    );
  }
}

/// App bar title: app name plus the open file name.
class _Title extends StatelessWidget {
  const _Title({this.fileName});

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (fileName == null) {
      return const Text('MDLector');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MDLector',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          fileName!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Empty state: no document open yet.
class _Welcome extends StatelessWidget {
  const _Welcome({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Read a Markdown book',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Open a Markdown or text file converted from PDF/EPUB and read '
                'it here. Tap any word to look up its meaning, or long-press to '
                'select a fragment and translate it. The text loads as you '
                'scroll.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.folder_open),
                label: const Text('Open file'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state.
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not open the document',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                message ?? 'Unknown error.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: onClose,
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Open another file'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
