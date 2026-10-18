import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../services/markdown_parser.dart';
import '../services/translation_service.dart';

/// Phase of the reader.
enum ReaderStatus { empty, loading, ready, error }

/// The open document: its file name and its parsed blocks.
class ReaderState {
  const ReaderState({
    this.status = ReaderStatus.empty,
    this.fileName,
    this.blocks = const <MdBlock>[],
    this.errorMessage,
  });

  final ReaderStatus status;
  final String? fileName;
  final List<MdBlock> blocks;
  final String? errorMessage;

  bool get hasDocument =>
      status == ReaderStatus.ready && blocks.isNotEmpty;
}

/// Opens files and parses them into blocks.
final readerProvider =
    NotifierProvider<ReaderNotifier, ReaderState>(ReaderNotifier.new);

class ReaderNotifier extends Notifier<ReaderState> {
  @override
  ReaderState build() => const ReaderState();

  /// Opens the native file picker and loads the chosen Markdown/text file.
  Future<void> pickAndOpen() async {
    if (state.status == ReaderStatus.loading) return;
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['md', 'markdown', 'mdown', 'txt', 'text'],
        withData: true,
        lockParentWindow: true,
        dialogTitle: 'Open a Markdown file',
      );
    } catch (_) {
      // Some platforms dislike custom extension filters: fall back to "any".
      result = await FilePicker.pickFiles(
        withData: true,
        lockParentWindow: true,
        dialogTitle: 'Open a Markdown file',
      );
    }
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    var bytes = file.bytes;
    if (bytes == null && file.path != null) {
      try {
        bytes = await File(file.path!).readAsBytes();
      } catch (_) {
        bytes = null;
      }
    }
    if (bytes == null) {
      state = const ReaderState(
        status: ReaderStatus.error,
        errorMessage: 'Could not read the selected file.',
      );
      return;
    }
    await loadBytes(bytes, file.name);
  }

  /// Parses UTF-8 [bytes] with [name] as the document title.
  Future<void> loadBytes(Uint8List bytes, String name) async {
    state = ReaderState(status: ReaderStatus.loading, fileName: name);
    try {
      final text = _decode(bytes);
      final blocks = parseMarkdown(text);
      if (blocks.isEmpty) {
        state = ReaderState(
          status: ReaderStatus.error,
          fileName: name,
          errorMessage: 'The file has no readable content.',
        );
        return;
      }
      state = ReaderState(
        status: ReaderStatus.ready,
        fileName: name,
        blocks: blocks,
      );
    } catch (error) {
      state = ReaderState(
        status: ReaderStatus.error,
        fileName: name,
        errorMessage: 'Failed to parse the document: $error',
      );
    }
  }

  /// Closes the current document and returns to the welcome screen.
  void close() => state = const ReaderState();

  String _decode(Uint8List bytes) {
    var data = bytes;
    // Strip a UTF-8 BOM if present.
    if (data.length >= 3 &&
        data[0] == 0xEF &&
        data[1] == 0xBB &&
        data[2] == 0xBF) {
      data = data.sublist(3);
    }
    try {
      return utf8.decode(data);
    } catch (_) {
      return utf8.decode(data, allowMalformed: true);
    }
  }
}

/// HTTP client shared by the translation service.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Google Translate service.
final translationServiceProvider = Provider<GoogleTranslationService>((ref) {
  return GoogleTranslationService(client: ref.watch(httpClientProvider));
});
