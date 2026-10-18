import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdlector/services/markdown_parser.dart';
import 'package:mdlector/ui/widgets/markdown_content.dart';

void main() {
  testWidgets('MarkdownContent renders blocks as selectable text', (
    tester,
  ) async {
    final blocks = parseMarkdown(
      '# Chapter One\n\n'
      'The quick brown fox jumps over the lazy dog.\n\n'
      '- first item\n'
      '- second item\n',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MarkdownContent(blocks: blocks, fontSize: 18),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Chapter One'), findsOneWidget);
    expect(
      find.text('The quick brown fox jumps over the lazy dog.'),
      findsOneWidget,
    );
    expect(find.text('first item'), findsOneWidget);
    expect(find.text('second item'), findsOneWidget);
    expect(find.byType(SelectableText), findsWidgets);
  });
}
