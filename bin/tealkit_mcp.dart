import 'dart:io';
import 'package:args/args.dart';
import 'package:tealkit_mcp/tealkit_mcp.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message')
    ..addOption('config', abbr: 'c', help: 'Path to custom config.yaml file')
    ..addOption('server-url', help: 'TealKit NAS/Server URL (e.g. http://192.168.1.50:8080)')
    ..addOption('server-key', help: 'TealKit Server API Key')
    ..addOption('rag-db', help: 'Path to RAG SQLite database directory');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Argument error: $e');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (results['help'] == true) {
    stdout.writeln('TealKit MCP Bridge Server (v1.0.0)');
    stdout.writeln('Extends Claude / Cursor with NAS Tasks, Deep RAG, and Mobile Push Alerts.\n');
    stdout.writeln('Usage: tealkit_mcp [options]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  // Load config
  McpBridgeConfig config;
  final configPath = results['config'] as String?;
  if (configPath != null && File(configPath).existsSync()) {
    config = McpBridgeConfig.fromFile(configPath);
  } else {
    config = McpBridgeConfig.fromEnvironment();
  }

  // CLI overrides
  if (results['server-url'] != null) {
    config.serverUrl = results['server-url'] as String;
  }
  if (results['server-key'] != null) {
    config.serverApiKey = results['server-key'] as String;
  }
  if (results['rag-db'] != null) {
    config.ragDbPath = results['rag-db'] as String;
  }

  // Launch MCP stdio server
  final server = McpServer(config: config);
  await server.runStdio();
}
