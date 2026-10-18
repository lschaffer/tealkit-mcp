import 'dart:io';
import 'package:path/path.dart' as p;

class RagConfig {
  bool enabled;
  String databasePath;
  List<String> folderSources;
  List<String> webSources;
  List<String> fileExtensions;
  int chunkSize;
  int chunkOverlap;
  String embeddingProvider;
  String embeddingModel;
  String embeddingRepo;
  String embeddingBaseUrl;
  String embeddingApiKey;
  String searchMode;
  int maxChunks;
  double minScore;
  int maxPages;

  RagConfig({
    this.enabled = true,
    String? databasePath,
    List<String>? folderSources,
    List<String>? webSources,
    List<String>? fileExtensions,
    this.chunkSize = 600,
    this.chunkOverlap = 100,
    this.embeddingProvider = 'none',
    this.embeddingModel = 'nomic-embed-text',
    this.embeddingRepo = '',
    this.embeddingBaseUrl = 'http://localhost:11434',
    this.embeddingApiKey = '',
    this.searchMode = 'hybrid',
    this.maxChunks = 5,
    this.minScore = 0.25,
    this.maxPages = 50,
  })  : databasePath = databasePath ?? defaultDatabasePath,
        folderSources = folderSources ?? ['./docs'],
        webSources = webSources ?? [],
        fileExtensions = fileExtensions ??
            ['.txt', '.md', '.docx', '.pdf', '.csv', '.json'];

  static String get defaultDatabasePath {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.normalize(p.join(home, '.tealkit_mcp', 'knowledge.db'));
  }
}
