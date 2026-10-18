import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Pure Dart lightweight PDF text extractor without heavy native C++ dependencies.
class PdfExtractor {
  static String? extractFromFile(File file) {
    if (!file.existsSync()) return null;
    try {
      final bytes = file.readAsBytesSync();
      return extractFromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  static String extractFromBytes(Uint8List bytes) {
    try {
      final raw = latin1.decode(bytes);
      final textBlocks = <String>[];

      final btRegex = RegExp(r'BT\s*(.*?)\s*ET', dotAll: true);
      final matches = btRegex.allMatches(raw);

      for (final match in matches) {
        final block = match.group(1) ?? '';
        final strRegex = RegExp(r'\((.*?)\)\s*T[jd]', dotAll: true);
        for (final sm in strRegex.allMatches(block)) {
          final content = sm.group(1) ?? '';
          if (content.isNotEmpty) {
            textBlocks.add(_cleanPdfString(content));
          }
        }
      }

      if (textBlocks.isNotEmpty) {
        return textBlocks.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      }

      final asciiRegex = RegExp(r'[\x20-\x7E\r\n]{5,}');
      final fallbackWords = asciiRegex
          .allMatches(raw)
          .map((m) => m.group(0) ?? '')
          .where((s) => !s.contains('/Filter') && !s.contains('endobj') && !s.contains('xref'))
          .take(500)
          .join(' ');

      return fallbackWords.trim();
    } catch (_) {
      return '';
    }
  }

  static String _cleanPdfString(String raw) {
    return raw
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\r', ' ')
        .replaceAll(r'\n', ' ')
        .replaceAll(r'\t', ' ');
  }
}
