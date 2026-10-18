import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'rag_config.dart';

class RagEmbedder {
  final RagConfig config;
  final http.Client _client = http.Client();

  RagEmbedder(this.config);

  bool get isEnabled =>
      config.embeddingProvider.isNotEmpty &&
      config.embeddingProvider != 'none';

  Future<Float32List?> embedText(String text) async {
    if (!isEnabled || text.trim().isEmpty) return null;

    final provider = config.embeddingProvider.toLowerCase().trim();
    if (provider == 'ollama') {
      return _embedOllama(text);
    } else if (provider == 'openai') {
      return _embedOpenAi(text);
    }
    return null;
  }

  Future<List<Float32List?>> embedBatch(
    List<String> texts, {
    void Function(int current, int total)? onProgress,
  }) async {
    if (!isEnabled || texts.isEmpty) {
      return List<Float32List?>.filled(texts.length, null);
    }

    final results = <Float32List?>[];
    for (int i = 0; i < texts.length; i++) {
      results.add(await embedText(texts[i]));
      onProgress?.call(i + 1, texts.length);
    }
    return results;
  }

  Future<Float32List?> _embedOllama(String text) async {
    try {
      final base = config.embeddingBaseUrl.isNotEmpty
          ? config.embeddingBaseUrl
          : 'http://localhost:11434';
      final url = Uri.parse('$base/api/embeddings');
      final resp = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': config.embeddingModel.isNotEmpty
              ? config.embeddingModel
              : 'nomic-embed-text',
          'prompt': text,
        }),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final embeddingList = (data['embedding'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList();
        if (embeddingList != null && embeddingList.isNotEmpty) {
          return Float32List.fromList(embeddingList);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Float32List?> _embedOpenAi(String text) async {
    try {
      final base = config.embeddingBaseUrl.isNotEmpty
          ? config.embeddingBaseUrl
          : 'https://api.openai.com/v1';
      final url = Uri.parse('$base/embeddings');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (config.embeddingApiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${config.embeddingApiKey}';
      }
      final resp = await _client.post(
        url,
        headers: headers,
        body: jsonEncode({
          'model': config.embeddingModel.isNotEmpty
              ? config.embeddingModel
              : 'text-embedding-3-small',
          'input': text,
        }),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = data['data'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final emb = (list.first['embedding'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList();
          if (emb != null) return Float32List.fromList(emb);
        }
      }
    } catch (_) {}
    return null;
  }

  static double cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0;
    double magA = 0.0;
    double magB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA <= 0.0 || magB <= 0.0) return 0.0;
    return dot / (math.sqrt(magA) * math.sqrt(magB));
  }

  static Uint8List vectorToBytes(Float32List vector) {
    return vector.buffer.asUint8List(vector.offsetInBytes, vector.lengthInBytes);
  }

  static Float32List bytesToVector(List<int> bytes) {
    final u8 = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    return u8.buffer.asFloat32List(u8.offsetInBytes, u8.lengthInBytes ~/ 4);
  }

  void dispose() {
    _client.close();
  }
}
