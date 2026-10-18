import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../bridge/push_service.dart';
import '../bridge/server_client.dart';
import '../config/mcp_bridge_config.dart';
import '../tools/mobile_tools.dart';
import '../tools/rag_tools.dart';
import '../tools/task_tools.dart';

class McpServer {
  final McpBridgeConfig config;
  late final TaskTools _taskTools;
  late final RagTools _ragTools;
  late final MobileTools _mobileTools;

  McpServer({McpBridgeConfig? config})
      : config = config ?? McpBridgeConfig.fromEnvironment() {
    _taskTools = TaskTools(TealKitServerBridge(this.config));
    _ragTools = RagTools(this.config);
    _mobileTools = MobileTools(TealKitMobileBridge(this.config));
  }

  List<Map<String, dynamic>> get allToolDefinitions => [
        ..._taskTools.definitions,
        ..._ragTools.definitions,
        ..._mobileTools.definitions,
      ];

  Future<void> runStdio() async {
    stderr.writeln('[tealkit-mcp] Starting TealKit MCP Bridge Server (v1.0.0)...');
    stderr.writeln('[tealkit-mcp] Registered ${allToolDefinitions.length} tools across 3 pillars: Tasks, RAG, Mobile');

    final lines = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final request = jsonDecode(trimmed);
        if (request is Map<String, dynamic>) {
          await _handleRequest(request);
        } else if (request is List) {
          for (final item in request) {
            if (item is Map<String, dynamic>) {
              await _handleRequest(item);
            }
          }
        }
      } catch (e, stack) {
        stderr.writeln('[tealkit-mcp] Error decoding message: $e\n$stack');
        _sendError(null, -32700, 'Parse error: $e');
      }
    }
  }

  Future<void> _handleRequest(Map<String, dynamic> msg) async {
    final id = msg['id'];
    final method = msg['method'] as String?;
    final params = (msg['params'] as Map<String, dynamic>?) ?? {};

    if (id == null) {
      if (method == 'notifications/initialized') {
        stderr.writeln('[tealkit-mcp] Client confirmed initialization.');
      } else if (method == r'$/cancelRequest') {
        stderr.writeln('[tealkit-mcp] Cancel request received: ${params['requestId']}');
      }
      return;
    }

    try {
      switch (method) {
        case 'initialize':
          _sendResult(id, {
            'protocolVersion': '2024-11-05',
            'capabilities': {
              'tools': {
                'listChanged': false,
              },
            },
            'serverInfo': {
              'name': 'tealkit-mcp',
              'version': '1.0.0',
            },
          });
          break;

        case 'ping':
          _sendResult(id, {});
          break;

        case 'tools/list':
          _sendResult(id, {
            'tools': allToolDefinitions,
          });
          break;

        case 'tools/call':
          final toolName = params['name'] as String?;
          final args = (params['arguments'] as Map<String, dynamic>?) ?? {};

          if (toolName == null) {
            _sendError(id, -32602, 'Missing required param "name"');
            return;
          }

          final response = await _dispatchToolCall(toolName, args);
          _sendResult(id, response);
          break;

        default:
          _sendError(id, -32601, 'Method not found: $method');
          break;
      }
    } catch (e, stack) {
      stderr.writeln('[tealkit-mcp] Error executing method $method: $e\n$stack');
      _sendError(id, -32603, 'Internal error: $e');
    }
  }

  Future<Map<String, dynamic>> _dispatchToolCall(
    String name,
    Map<String, dynamic> args,
  ) async {
    try {
      if (name.startsWith('tealkit_schedule_') ||
          name == 'tealkit_run_background' ||
          name == 'tealkit_get_job_status' ||
          name == 'tealkit_list_jobs') {
        return await _taskTools.execute(name, args);
      }

      if (name == 'tealkit_crawl_and_index' ||
          name == 'tealkit_index_local_docs' ||
          name == 'tealkit_search_knowledge' ||
          name == 'tealkit_get_source_doc') {
        return await _ragTools.execute(name, args);
      }

      if (name == 'tealkit_send_mobile_alert' ||
          name == 'tealkit_request_mobile_approval') {
        return await _mobileTools.execute(name, args);
      }

      return {
        'content': [
          {'type': 'text', 'text': 'Unknown tool: $name'}
        ],
        'isError': true,
      };
    } catch (e) {
      return {
        'content': [
          {'type': 'text', 'text': 'Tool execution failed: $e'}
        ],
        'isError': true,
      };
    }
  }

  void _sendResult(dynamic id, Map<String, dynamic> result) {
    final response = {
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    };
    stdout.writeln(jsonEncode(response));
  }

  void _sendError(dynamic id, int code, String message, [dynamic data]) {
    final response = {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      },
    };
    stdout.writeln(jsonEncode(response));
  }
}
