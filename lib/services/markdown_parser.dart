/// Block-level Markdown parser tuned for reading converted books.
///
/// The goal is NOT a faithful CommonMark implementation: it is a small,
/// dependency-free parser that splits a document into *blocks* (headings,
/// paragraphs, list items, blockquotes, code fences, rules) so the reader can
/// render them lazily in a `ListView.builder`. Everything is plain text, which
/// is what the reader shows: normal, readable prose.
library;

/// Kind of a Markdown block.
enum MdBlockType { heading, paragraph, listItem, blockquote, code, rule }

/// One renderable unit of the document.
class MdBlock {
  const MdBlock({
    required this.type,
    this.text = '',
    this.level = 0,
    this.ordered = false,
    this.marker = '•',
    this.language,
  });

  const MdBlock.heading(String text, {required int level})
      : this(type: MdBlockType.heading, text: text, level: level);

  const MdBlock.paragraph(String text)
      : this(type: MdBlockType.paragraph, text: text);

  const MdBlock.listItem(
    String text, {
    required bool ordered,
    required String marker,
  }) : this(
          type: MdBlockType.listItem,
          text: text,
          ordered: ordered,
          marker: marker,
        );

  const MdBlock.blockquote(String text)
      : this(type: MdBlockType.blockquote, text: text);

  const MdBlock.code(String text, {String? language})
      : this(type: MdBlockType.code, text: text, language: language);

  const MdBlock.rule() : this(type: MdBlockType.rule);

  final MdBlockType type;

  /// Inline text already cleaned of Markdown syntax (for [paragraph],
  /// [heading], [listItem] and [blockquote]) or the raw content of a code
  /// block.
  final String text;

  /// Heading level 1..6 (only for [MdBlockType.heading]).
  final int level;

  /// `true` for an ordered list item (`1.`), `false` for a bullet (`-`).
  final bool ordered;

  /// Bullet or number shown before a list item.
  final String marker;

  /// Info string of a fenced code block (language), may be empty.
  final String? language;
}

final RegExp _fenceRe = RegExp(r'^\s*(```|~~~)(.*)$');
final RegExp _headingRe = RegExp(r'^(#{1,6})\s+(.*?)\s*#*\s*$');
final RegExp _ruleRe =
    RegExp(r'^\s*((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$');
final RegExp _quoteRe = RegExp(r'^\s*>\s?(.*)$');
final RegExp _listRe = RegExp(r'^(\s*)([-*+]|\d+[.)])\s+(.*)$');
final RegExp _orderedRe = RegExp(r'^\d');

/// Split [source] into renderable blocks.
List<MdBlock> parseMarkdown(String source) {
  final lines = source
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');

  final blocks = <MdBlock>[];
  final paragraph = <String>[];
  final quote = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    final text = cleanInline(paragraph.join(' ').trim());
    if (text.isNotEmpty) blocks.add(MdBlock.paragraph(text));
    paragraph.clear();
  }

  void flushQuote() {
    if (quote.isEmpty) return;
    final text = cleanInline(quote.join(' ').trim());
    if (text.isNotEmpty) blocks.add(MdBlock.blockquote(text));
    quote.clear();
  }

  void flushAll() {
    flushParagraph();
    flushQuote();
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];

    // Fenced code block.
    final fence = _fenceRe.firstMatch(line);
    if (fence != null) {
      flushAll();
      final marker = fence.group(1)!;
      final lang = fence.group(2)!.trim();
      i++;
      final buffer = <String>[];
      while (i < lines.length && !lines[i].trimLeft().startsWith(marker)) {
        buffer.add(lines[i]);
        i++;
      }
      if (i < lines.length) i++; // closing fence
      blocks.add(MdBlock.code(buffer.join('\n'), language: lang));
      continue;
    }

    // Blank line: closes the current paragraph / blockquote.
    if (line.trim().isEmpty) {
      flushAll();
      i++;
      continue;
    }

    final heading = _headingRe.firstMatch(line);
    if (heading != null) {
      flushAll();
      blocks.add(MdBlock.heading(
        cleanInline(heading.group(2)!.trim()),
        level: heading.group(1)!.length,
      ));
      i++;
      continue;
    }

    if (_ruleRe.hasMatch(line)) {
      flushAll();
      blocks.add(const MdBlock.rule());
      i++;
      continue;
    }

    final quoteMatch = _quoteRe.firstMatch(line);
    if (quoteMatch != null) {
      flushParagraph();
      quote.add(quoteMatch.group(1)!);
      i++;
      continue;
    }

    final list = _listRe.firstMatch(line);
    if (list != null) {
      flushAll();
      final marker = list.group(2)!;
      final ordered = _orderedRe.hasMatch(marker);
      final text = cleanInline(list.group(3)!.trim());
      if (text.isNotEmpty) {
        blocks.add(MdBlock.listItem(
          text,
          ordered: ordered,
          marker: ordered ? marker : '•',
        ));
      }
      i++;
      continue;
    }

    // Ordinary paragraph line.
    flushQuote();
    paragraph.add(line.trim());
    i++;
  }

  flushAll();
  return blocks;
}

/// Strip inline Markdown syntax so the reader shows clean prose.
String cleanInline(String raw) {
  var out = raw;
  // Images -> alt text.
  out = out.replaceAllMapped(
    RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
    (m) => m[1] ?? '',
  );
  // Links -> link text.
  out = out.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]*\)'),
    (m) => m[1] ?? '',
  );
  // Reference-style links [text][id] -> text.
  out = out.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\[[^\]]*\]'),
    (m) => m[1] ?? '',
  );
  // Inline code.
  out = out.replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m[1] ?? '');
  // Bold / italic / strikethrough markers.
  out = out.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1] ?? '');
  out = out.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m[1] ?? '');
  out = out.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1] ?? '');
  out = out.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1] ?? '');
  out = out.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (m) => m[1] ?? '');
  // Inline HTML tags.
  out = out.replaceAll(RegExp(r'<[^>]+>'), '');
  // Backslash escapes for common punctuation.
  out = out.replaceAllMapped(RegExp(r'\\([\\`*_{}\[\]()#+\-.!])'), (m) => m[1] ?? '');
  return out.trim();
}

/// A run of characters in a line: either a word or a separator.
class TokenSpan {
  const TokenSpan(this.start, this.end, this.isWord);

  final int start;
  final int end;
  final bool isWord;
}

final RegExp _wordRe = RegExp(r"[\p{L}\p{N}][\p{L}\p{N}'’\-]*", unicode: true);

/// Split [text] into word / separator spans, keeping the exact offsets so a
/// tap position can be mapped back to the word under the finger.
List<TokenSpan> tokenize(String text) {
  final spans = <TokenSpan>[];
  var last = 0;
  for (final match in _wordRe.allMatches(text)) {
    if (match.start > last) spans.add(TokenSpan(last, match.start, false));
    spans.add(TokenSpan(match.start, match.end, true));
    last = match.end;
  }
  if (last < text.length) spans.add(TokenSpan(last, text.length, false));
  return spans;
}

/// Strip leading/trailing punctuation from [word], keeping letters/numbers.
String cleanWord(String word) => word
    .replaceAll(RegExp(r"^[^\p{L}\p{N}]+", unicode: true), '')
    .replaceAll(RegExp(r"[^\p{L}\p{N}]+$", unicode: true), '')
    .trim();
