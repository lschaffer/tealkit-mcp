import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class McpBridgeConfig {
  String serverUrl;
  String serverApiKey;
  String ragDbPath;
  String pushEndpoint;
  String pushAuthToken;

  McpBridgeConfig({
    this.serverUrl = 'https://tealkit.dev',
    this.serverApiKey = '',
    this.ragDbPath = '',
    this.pushEndpoint = '',
    this.pushAuthToken = '',
  }) {
    if (ragDbPath.isEmpty) {
      ragDbPath = p.join(defaultDataDir, 'knowledge.db');
    }
  }

  static String get defaultDataDir {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.join(home, '.tealkit_mcp');
  }

  static McpBridgeConfig fromEnvironment() => load();

  static McpBridgeConfig fromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return load();

    try {
      final yaml = loadYaml(file.readAsStringSync()) as Map?;
      if (yaml != null) {
        final server = yaml['server'] as Map?;
        final rag = yaml['rag'] as Map?;
        final push = yaml['push'] as Map?;
        return McpBridgeConfig(
          serverUrl: (server?['url'] as String?) ??
              Platform.environment['TEALKIT_SERVER_URL'] ??
              'https://tealkit.dev',
          serverApiKey: (server?['api_key'] as String?) ??
              Platform.environment['TEALKIT_SERVER_KEY'] ??
              '',
          ragDbPath: (rag?['database_path'] as String?) ??
              p.join(defaultDataDir, 'knowledge.db'),
          pushEndpoint: (push?['endpoint'] as String?) ??
              Platform.environment['TEALKIT_PUSH_URL'] ??
              '',
          pushAuthToken: (push?['auth_token'] as String?) ??
              Platform.environment['TEALKIT_PUSH_KEY'] ??
              '',
        );
      }
    } catch (_) {}
    return load();
  }

  static McpBridgeConfig load() {
    final candidateDirs = [
      Directory.current.path,
      defaultDataDir,
    ];

    for (final dir in candidateDirs) {
      final file = File(p.join(dir, 'config.yaml'));
      if (file.existsSync()) {
        return fromFile(file.path);
      }
    }

    return McpBridgeConfig(
      serverUrl: Platform.environment['TEALKIT_SERVER_URL'] ?? 'https://tealkit.dev',
      serverApiKey: Platform.environment['TEALKIT_SERVER_KEY'] ?? '',
      ragDbPath: p.join(defaultDataDir, 'knowledge.db'),
      pushEndpoint: Platform.environment['TEALKIT_PUSH_URL'] ?? '',
      pushAuthToken: Platform.environment['TEALKIT_PUSH_KEY'] ?? '',
    );
  }
}
