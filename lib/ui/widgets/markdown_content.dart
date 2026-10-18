import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/markdown_parser.dart';
import 'translation_dialogs.dart';

/// The scrolling reader.
///
/// Renders the parsed blocks with a `ListView.builder`, so only the blocks
/// near the viewport are built and laid out: a long book loads as you scroll
/// instead of building every paragraph up front.
class MarkdownContent extends ConsumerStatefulWidget {
  const MarkdownContent({
    super.key,
    required this.blocks,
    required this.fontSize,
  });

  final List<MdBlock> blocks;
  final double fontSize;

  @override
  ConsumerState<MarkdownContent> createState() => _MarkdownContentState();
}

class _MarkdownContentState extends ConsumerState<MarkdownContent> {
  void _onWord(String word) => showWordMeaning(context, ref, word);

  void _onSelection(String text) => showTextTranslation(context, ref, text);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 120),
        itemCount: widget.blocks.length,
        itemBuilder: (context, index) {
          return MdBlockView(
            block: widget.blocks[index],
            fontSize: widget.fontSize,
            onWordTap: _onWord,
            onTranslateSelection: _onSelection,
          );
        },
      ),
    );
  }
}

/// Renders one [MdBlock] with plain, readable typography.
class MdBlockView extends StatelessWidget {
  const MdBlockView({
    super.key,
    required this.block,
    required this.fontSize,
    required this.onWordTap,
    required this.onTranslateSelection,
  });

  final MdBlock block;
  final double fontSize;
  final ValueChanged<String> onWordTap;
  final ValueChanged<String> onTranslateSelection;

  static const EdgeInsets _horizontal = EdgeInsets.symmetric(horizontal: 24);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textColor = scheme.onSurface;

    switch (block.type) {
      case MdBlockType.rule:
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Divider(height: 1),
        );

      case MdBlockType.heading:
        final scale = switch (block.level) {
          1 => 1.9,
          2 => 1.6,
          3 => 1.35,
          4 => 1.18,
          5 => 1.08,
          _ => 1.0,
        };
        return Padding(
          padding: EdgeInsets.fromLTRB(24, block.level <= 2 ? 26 : 18, 24, 6),
          child: BlockText(
            text: block.text,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize * scale,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            onWordTap: onWordTap,
            onTranslateSelection: onTranslateSelection,
          ),
        );

      case MdBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7).add(_horizontal),
          child: BlockText(
            text: block.text,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              height: 1.5,
            ),
            onWordTap: onWordTap,
            onTranslateSelection: onTranslateSelection,
          ),
        );

      case MdBlockType.listItem:
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 3, 24, 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  block.ordered ? block.marker : '•',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: fontSize,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: BlockText(
                  text: block.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    height: 1.5,
                  ),
                  onWordTap: onWordTap,
                  onTranslateSelection: onTranslateSelection,
                ),
              ),
            ],
          ),
        );

      case MdBlockType.blockquote:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8).add(_horizontal),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: scheme.primary, width: 3),
              ),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
            child: BlockText(
              text: block.text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: fontSize,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
              onWordTap: onWordTap,
              onTranslateSelection: onTranslateSelection,
            ),
          ),
        );

      case MdBlockType.code:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8).add(_horizontal),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: BlockText(
                text: block.text,
                tappable: false,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontFamily: 'monospace',
                  fontSize: fontSize * 0.9,
                  height: 1.4,
                ),
                onTranslateSelection: onTranslateSelection,
              ),
            ),
          ),
        );
    }
  }
}

/// A selectable run of text whose individual words can be tapped.
///
/// A [SelectableText.rich] gives native selection (long-press / drag) with a
/// context menu; each word additionally carries a [TapGestureRecognizer], so a
/// plain tap opens the word meaning. The recognizers are owned and disposed by
/// this state, and rebuilt only when the text, style or interactivity change.
class BlockText extends StatefulWidget {
  const BlockText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
    this.tappable = true,
    this.onWordTap,
    this.onTranslateSelection,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final bool tappable;
  final ValueChanged<String>? onWordTap;
  final ValueChanged<String>? onTranslateSelection;

  @override
  State<BlockText> createState() => _BlockTextState();
}

class _BlockTextState extends State<BlockText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];
  TextSpan? _span;
  String? _spanText;
  TextStyle? _spanStyle;
  bool? _spanTappable;

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  TextSpan _ensureSpan() {
    if (_span != null &&
        _spanText == widget.text &&
        _spanStyle == widget.style &&
        _spanTappable == widget.tappable) {
      return _span!;
    }
    _disposeRecognizers();

    final children = <TextSpan>[];
    final canTap = widget.tappable && widget.onWordTap != null;
    for (final token in tokenize(widget.text)) {
      final piece = widget.text.substring(token.start, token.end);
      if (!token.isWord || !canTap) {
        children.add(TextSpan(text: piece));
        continue;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onWordTap!(piece);
      _recognizers.add(recognizer);
      children.add(TextSpan(text: piece, recognizer: recognizer));
    }

    _span = TextSpan(children: children);
    _spanText = widget.text;
    _spanStyle = widget.style;
    _spanTappable = widget.tappable;
    return _span!;
  }

  Widget _buildContextMenu(BuildContext context, EditableTextState state) {
    final items = state.contextMenuButtonItems;
    final selection = state.textEditingValue.selection;
    final selected = selection
        .textInside(state.textEditingValue.text)
        .trim();
    if (selected.isNotEmpty && widget.onTranslateSelection != null) {
      items.insert(
        0,
        ContextMenuButtonItem(
          label: 'Translate',
          onPressed: () {
            state.hideToolbar();
            widget.onTranslateSelection!(selected);
          },
        ),
      );
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      _ensureSpan(),
      style: widget.style,
      textAlign: widget.textAlign,
      contextMenuBuilder: _buildContextMenu,
    );
  }
}
