import 'package:flutter_test/flutter_test.dart';
import 'package:mdlector/services/markdown_parser.dart';

void main() {
  group('parseMarkdown', () {
    test('splits headings and paragraphs', () {
      final blocks = parseMarkdown('# Title\n\nHello **world**.\n');
      expect(blocks.length, 2);
      expect(blocks[0].type, MdBlockType.heading);
      expect(blocks[0].level, 1);
      expect(blocks[0].text, 'Title');
      expect(blocks[1].type, MdBlockType.paragraph);
      expect(blocks[1].text, 'Hello world.');
    });

    test('keeps fenced code intact', () {
      final blocks = parseMarkdown('```dart\nvoid main() {}\n```\n');
      expect(blocks.single.type, MdBlockType.code);
      expect(blocks.single.text, 'void main() {}');
      expect(blocks.single.language, 'dart');
    });

    test('parses lists and blockquotes', () {
      final blocks = parseMarkdown('- one\n- two\n\n> quote here\n');
      expect(blocks.length, 3);
      expect(blocks[0].type, MdBlockType.listItem);
      expect(blocks[0].marker, '•');
      expect(blocks[2].type, MdBlockType.blockquote);
      expect(blocks[2].text, 'quote here');
    });
  });

  group('tokenize', () {
    test('marks words and separators with exact offsets', () {
      const text = "It's a test, really.";
      final spans = tokenize(text);
      final words = [
        for (final s in spans)
          if (s.isWord) text.substring(s.start, s.end),
      ];
      expect(words, ["It's", 'a', 'test', 'really']);
    });
  });

  test('cleanWord strips punctuation', () {
    expect(cleanWord('"Hello,"'), 'Hello');
  });
}
