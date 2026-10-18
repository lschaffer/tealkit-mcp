import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../config/mcp_bridge_config.dart';
import '../rag/extractors/docx_extractor.dart';
import '../rag/extractors/pdf_extractor.dart';
import '../rag/extractors/text_extractor.dart';
import '../rag/extractors/web_crawler.dart';
import '../rag/rag_chunker.dart';
import '../rag/rag_config.dart';
import '../rag/rag_service.dart';

class RagTools {
  final McpBridgeConfig bridgeConfig;
  late final RagService _ragService;
  bool _initialized = false;

  RagTools(this.bridgeConfig) {
    final ragConfig = RagConfig(
      databasePath: bridgeConfig.ragDbPath,
      embeddingProvider: 'none',
      searchMode: 'hybrid',
    );
    _ragService = RagService(ragConfig);
  }

  void _ensureInit() {
    if (_initialized) return;
    final parent = File(bridgeConfig.ragDbPath).parent;
    if (!parent.existsSync()) parent.createSync(recursive: true);
    _ragService.init();
    _initialized = true;
  }

  List<Map<String, dynamic>> get definitions => [
        {
          'name': 'tealkit_crawl_and_index',
          'description':
              'Recursively crawls a website documentation tree (up to max_pages) and indexes it into the local offline RAG knowledge base.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'url': {
                'type': 'string',
                'description': 'Root URL to start recursive crawling (e.g. https://docs.flutter.dev)',
              },
              'max_pages': {
                'type': 'integer',
                'description': 'Maximum number of pages to crawl (default: 30, max: 200)',
                'default': 30,
              },
            },
            'required': ['url'],
          },
        },
        {
          'name': 'tealkit_index_local_docs',
          'description':
              'Indexes a local directory containing PDFs, Word (.docx), Markdown (.md), or text files into the knowledge base.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'folder_path': {
                'type': 'string',
                'description': 'Absolute path to the directory containing documents',
              },
            },
            'required': ['folder_path'],
          },
        },
        {
          'name': 'tealkit_search_knowledge',
          'description':
              'Searches the offline local knowledge base (crawled web documentation and local files) with exact citations, file paths, and line numbers.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'query': {
                'type': 'string',
                'description': 'Search query or question',
              },
              'max_results': {
                'type': 'integer',
                'description': 'Maximum number of chunks to return (default: 5)',
                'default': 5,
              },
            },
            'required': ['query'],
          },
        },
        {
          'name': 'tealkit_get_source_doc',
          'description':
              'Retrieves the full stored content of a document or web page from the knowledge base by URL or filepath.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'source': {
                'type': 'string',
                'description': 'File path or URL returned in search citations',
              },
            },
            'required': ['source'],
          },
        },
      ];

  Future<Map<String, dynamic>> execute(String name, Map<String, dynamic> arguments) async {
    _ensureInit();

    try {
      switch (name) {
        case 'tealkit_crawl_and_index':
          final urlStr = arguments['url'] as String? ?? '';
          final maxPages = (arguments['max_pages'] as num?)?.toInt() ?? 30;

          final uri = Uri.tryParse(urlStr);
          if (uri == null || !uri.hasScheme) {
            return {
              'content': [{'type': 'text', 'text': 'Error: Invalid URL: $urlStr'}],
              'isError': true,
            };
          }

          final crawler = WebCrawler(maxPages: maxPages);
          final pages = await crawler.crawlSeed(uri, maxPages: maxPages);

          int totalChunks = 0;
          for (final page in pages) {
            final pageUrl = page.url.toString();
            final contentHash = md5.convert(utf8.encode(page.text)).toString();
            final chunks = RagChunker.splitText(
              text: page.text,
              chunkSize: 600,
              chunkOverlap: 100,
            );

            final docId = 'web_${md5.convert(utf8.encode(pageUrl))}';
            final chunkMaps = <Map<String, dynamic>>[];
            for (final c in chunks) {
              chunkMaps.add({
                'id': '${docId}_${c.index}',
                'index': c.index,
                'content': c.text,
                'token_count': c.tokenCount,
                'line_start': c.startLine,
                'line_end': c.endLine,
                'embedding': null,
              });
            }

            _ragService.database.saveDocumentWithChunks(
              documentId: docId,
              sourceType: 'web',
              uri: pageUrl,
              title: page.title.isNotEmpty ? page.title : pageUrl,
              contentHash: contentHash,
              fileSize: page.text.length,
              lastModified: DateTime.now().millisecondsSinceEpoch,
              chunks: chunkMaps,
            );
            totalChunks += chunkMaps.length;
          }

          final resultText = 'Successfully crawled ${pages.length} pages from $urlStr. Indexed $totalChunks chunks into offline RAG database at ${_ragService.config.databasePath}.';
          return {
            'content': [{'type': 'text', 'text': resultText}],
            'isError': false,
          };

        case 'tealkit_index_local_docs':
          final folderPath = arguments['folder_path'] as String? ?? '';
          final dir = Directory(folderPath);
          if (!dir.existsSync()) {
            return {
              'content': [{'type': 'text', 'text': 'Error: Directory does not exist: $folderPath'}],
              'isError': true,
            };
          }

          final files = dir.listSync(recursive: true).whereType<File>().toList();
          int indexedDocs = 0;
          int totalChunks = 0;

          for (final f in files) {
            final ext = p.extension(f.path).toLowerCase();
            if (!['.txt', '.md', '.pdf', '.docx', '.csv', '.json'].contains(ext)) continue;

            String? text;
            if (ext == '.docx') {
              text = DocxExtractor.extractFromFile(f);
            } else if (ext == '.pdf') {
              text = PdfExtractor.extractFromFile(f);
            } else {
              text = TextExtractor.extractFromFile(f);
            }

            if (text == null || text.trim().isEmpty) continue;

            final contentHash = md5.convert(utf8.encode(text)).toString();
            final chunks = RagChunker.splitText(text: text, chunkSize: 600, chunkOverlap: 100);
            final docId = 'doc_${md5.convert(utf8.encode(f.path))}';
            final chunkMaps = chunks.map((c) => {
              'id': '${docId}_${c.index}',
              'index': c.index,
              'content': c.text,
              'token_count': c.tokenCount,
              'line_start': c.startLine,
              'line_end': c.endLine,
              'embedding': null,
            }).toList();

            _ragService.database.saveDocumentWithChunks(
              documentId: docId,
              sourceType: 'file',
              uri: f.path,
              title: p.basename(f.path),
              contentHash: contentHash,
              fileSize: text.length,
              lastModified: f.lastModifiedSync().millisecondsSinceEpoch,
              chunks: chunkMaps,
            );

            indexedDocs++;
            totalChunks += chunkMaps.length;
          }

          final resultText = 'Indexed $indexedDocs documents ($totalChunks chunks) from $folderPath into offline RAG database.';
          return {
            'content': [{'type': 'text', 'text': resultText}],
            'isError': false,
          };

        case 'tealkit_search_knowledge':
          final query = arguments['query'] as String? ?? '';
          final maxResults = (arguments['max_results'] as num?)?.toInt() ?? 5;

          final results = await _ragService.search(query, limit: maxResults);
          if (results.isEmpty) {
            return {
              'content': [{'type': 'text', 'text': 'No matching content found in knowledge base for query: "$query".'}],
              'isError': false,
            };
          }

          final sb = StringBuffer('Search Results (${results.length} citations):\n\n');
          for (var i = 0; i < results.length; i++) {
            final r = results[i];
            sb.writeln('### [${i + 1}] ${r.documentTitle ?? r.documentUri}');
            sb.writeln('Source: ${r.documentUri} (Lines ${r.lineStart ?? 1}-${r.lineEnd ?? '?'})');
            sb.writeln('Relevance Score: ${r.score.toStringAsFixed(3)} [${r.matchType}]');
            sb.writeln('```\n${r.content}\n```\n');
          }
          return {
            'content': [{'type': 'text', 'text': sb.toString()}],
            'isError': false,
          };

        case 'tealkit_get_source_doc':
          final source = arguments['source'] as String? ?? '';
          final doc = _ragService.database.getDocumentByUri(source);
          if (doc == null) {
            return {
              'content': [{'type': 'text', 'text': 'Document not found in knowledge base: $source'}],
              'isError': true,
            };
          }
          final sb = StringBuffer();
          sb.writeln('Document URI: ${doc['uri']}');
          sb.writeln('Title: ${doc['title']}');
          sb.writeln('Type: ${doc['source_type']} | Size: ${doc['file_size']} chars');
          sb.writeln('Hash: ${doc['content_hash']}\n');
          return {
            'content': [{'type': 'text', 'text': sb.toString()}],
            'isError': false,
          };

        default:
          return {
            'content': [{'type': 'text', 'text': 'Unknown RAG tool: $name'}],
            'isError': true,
          };
      }
    } catch (e) {
      return {
        'content': [{'type': 'text', 'text': 'RAG tool error: $e'}],
        'isError': true,
      };
    }
  }
}
