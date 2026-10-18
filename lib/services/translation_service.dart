import 'dart:convert';

import 'package:http/http.dart' as http;

/// Translation of a single word plus the dictionary senses Google reports.
class WordMeaning {
  const WordMeaning({this.translation, this.senses = const <String>[]});

  /// Isolated translation of the word, or `null` if it is already in the
  /// target language / could not be translated / request failed.
  final String? translation;

  /// Dictionary entries (`dt=bd`): alternative meanings, in the target
  /// language. Empty when Google offers none.
  final List<String> senses;

  bool get isEmpty =>
      (translation == null || translation!.isEmpty) && senses.isEmpty;
}

/// Google Translate over its public `gtx` endpoint (no API key).
///
/// This is a trimmed copy of the service used by Lylyrics: the same endpoint,
/// the same defensive JSON parsing. It keeps the two capabilities the reader
/// needs:
/// * [translateText] — a phrase or sentence (used for a selected fragment).
/// * [lookUp] — a single word plus its dictionary senses (used on tap).
class GoogleTranslationService {
  // ignore: prefer_initializing_formals
  GoogleTranslationService({http.Client? client}) : _client = client;

  final http.Client? _client;

  /// Hard cap on the query length so no URL or request exceeds the endpoint
  /// limits (~5000 characters per request).
  static const int maxQueryLength = 4500;

  /// Translates [text] into [target]. Returns `null` when there is nothing to
  /// translate (empty input), the text already *is* in [target], or the
  /// request failed.
  Future<String?> translateText(String text, {String target = 'en'}) async {
    final clean = _cap(text);
    if (clean.isEmpty) return null;
    final decoded = await _gtx(clean, target: target);
    if (decoded == null) return null;
    return _joinSegments(decoded[0]);
  }

  /// Looks up a single [word]: its isolated translation and its senses.
  Future<WordMeaning> lookUp(String word, {String target = 'en'}) async {
    final clean = cleanWord(word);
    if (clean.isEmpty) return const WordMeaning();
    final decoded = await _gtx(
      _cap(clean),
      dts: const <String>['t', 'bd'],
      target: target,
    );
    if (decoded == null) return const WordMeaning();

    final translation = _joinSegments(decoded[0]);
    final senses = <String>[];
    final rawBd = decoded.length > 1 ? decoded[1] : null;
    if (rawBd is List) {
      for (final entry in rawBd) {
        if (entry is! List || entry.length < 2) continue;
        final alternatives = entry[1];
        if (alternatives is! List) continue;
        for (final sense in alternatives) {
          if (sense is String && sense.trim().isNotEmpty) {
            senses.add(sense.trim());
          }
        }
      }
    }
    return WordMeaning(translation: translation, senses: senses);
  }

  String _cap(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= maxQueryLength) return trimmed;
    return trimmed.substring(0, maxQueryLength);
  }

  /// Single request to the `gtx` endpoint. Returns the decoded JSON list, or
  /// `null` on failure / timeout / when the detected source language already
  /// equals [target].
  Future<List<dynamic>?> _gtx(
    String text, {
    List<String> dts = const <String>['t'],
    String target = 'en',
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return null;
    final client = _client ?? http.Client();
    final shouldClose = _client == null;
    try {
      var queryString = 'client=gtx&sl=auto&tl=$target';
      for (final dt in dts) {
        queryString += '&dt=$dt';
      }
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?$queryString&q=${Uri.encodeComponent(clean)}',
      );
      final response = await client
          .get(uri, headers: const {'User-Agent': 'MDLector/1.0.0'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return null;

      // Detected language is usually decoded[2] ("en", "es"...). If it already
      // matches the target there is nothing to translate.
      final detected =
          decoded.length > 2 ? decoded[2]?.toString() : null;
      if (detected == target) return null;
      return decoded;
    } catch (_) {
      return null;
    } finally {
      if (shouldClose) client.close();
    }
  }

  /// Concatenates the `dt=t` segments (`[translation, original, ...]`) into a
  /// single string. Returns `null` when the shape is unexpected or empty.
  String? _joinSegments(Object? raw) {
    if (raw is! List) return null;
    final buffer = StringBuffer();
    for (final segment in raw) {
      if (segment is List && segment.isNotEmpty && segment[0] is String) {
        buffer.write(segment[0] as String);
      }
    }
    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }
}

/// Strip leading/trailing punctuation, keeping letters and numbers.
String cleanWord(String word) => word
    .replaceAll(RegExp(r"^[^\p{L}\p{N}]+", unicode: true), '')
    .replaceAll(RegExp(r"[^\p{L}\p{N}]+$", unicode: true), '')
    .trim();
