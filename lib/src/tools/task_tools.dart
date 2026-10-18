import '../bridge/server_client.dart';

class TaskTools {
  final TealKitServerBridge bridge;

  TaskTools(this.bridge);

  List<Map<String, dynamic>> get definitions => [
        {
          'name': 'tealkit_schedule_job',
          'description':
              'Schedules a persistent, recurring background task (cron job) on the TealKit Server or NAS.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'cron': {
                'type': 'string',
                'description': 'Standard 5-field cron expression (e.g. 0 3 * * * for daily at 3 AM)',
              },
              'task_name': {
                'type': 'string',
                'description': 'Human-readable name for the scheduled task',
              },
              'command_or_prompt': {
                'type': 'string',
                'description': 'The prompt, shell command, or AgentSkill to execute periodically',
              },
              'profile': {
                'type': 'string',
                'description': 'Optional execution profile or environment (default: default)',
                'default': 'default',
              },
            },
            'required': ['cron', 'task_name', 'command_or_prompt'],
          },
        },
        {
          'name': 'tealkit_run_background',
          'description':
              'Dispatches an asynchronous, long-running task to the TealKit server/NAS (fire-and-forget).',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'task': {
                'type': 'string',
                'description': 'Task ID, registered workflow name, or shell command to execute',
              },
              'arguments': {
                'type': 'string',
                'description': 'Optional parameters or payload JSON for the background execution',
              },
              'timeout_minutes': {
                'type': 'integer',
                'description': 'Maximum execution timeout in minutes (default: 60)',
                'default': 60,
              },
            },
            'required': ['task'],
          },
        },
        {
          'name': 'tealkit_get_job_status',
          'description':
              'Inspects the execution logs, exit status, and progress of a background or scheduled job.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'job_id': {
                'type': 'string',
                'description': 'Unique execution Job ID returned by tealkit_run_background',
              },
              'tail_lines': {
                'type': 'integer',
                'description': 'Number of trailing log lines to retrieve (default: 50)',
                'default': 50,
              },
            },
            'required': ['job_id'],
          },
        },
        {
          'name': 'tealkit_list_jobs',
          'description':
              'Lists all configured, scheduled, and currently running background jobs on the TealKit server.',
          'inputSchema': {
            'type': 'object',
            'properties': {},
          },
        },
      ];

  Future<Map<String, dynamic>> execute(String name, Map<String, dynamic> arguments) async {
    try {
      switch (name) {
        case 'tealkit_schedule_job':
          final cron = arguments['cron'] as String? ?? '';
          final taskName = arguments['task_name'] as String? ?? '';
          final command = arguments['command_or_prompt'] as String? ?? '';
          final profile = arguments['profile'] as String? ?? 'default';

          final res = await bridge.scheduleJob(
            cronExpression: cron,
            taskName: taskName,
            commandOrPrompt: command,
            profile: profile,
          );
          final text = 'Scheduled job "$taskName" ($cron): ${res['job_id'] ?? 'registered'}. Note: ${res['note'] ?? 'active'}';
          return {'content': [{'type': 'text', 'text': text}], 'isError': false};

        case 'tealkit_run_background':
          final task = arguments['task'] as String? ?? '';
          final args = arguments['arguments'] as String?;
          final timeout = (arguments['timeout_minutes'] as num?)?.toInt() ?? 60;

          final res = await bridge.runBackground(
            taskNameOrId: task,
            arguments: args,
            timeoutMinutes: timeout,
          );
          final text = 'Dispatched background task "$task": Job ID ${res['job_id'] ?? 'dispatched'}. Status: ${res['status'] ?? 'queued'}';
          return {'content': [{'type': 'text', 'text': text}], 'isError': false};

        case 'tealkit_get_job_status':
          final jobId = arguments['job_id'] as String? ?? '';
          final tail = (arguments['tail_lines'] as num?)?.toInt() ?? 50;
          final res = await bridge.getJobStatus(jobId, tailLines: tail);
          final text = 'Job Status [$jobId]: ${res['status']}\nLogs:\n${res['logs'] ?? 'No logs yet.'}';
          return {'content': [{'type': 'text', 'text': text}], 'isError': false};

        case 'tealkit_list_jobs':
          final tasks = await bridge.listTasks();
          if (tasks.isEmpty) {
            return {'content': [{'type': 'text', 'text': 'No scheduled or running jobs currently found on server.'}], 'isError': false};
          }
          final sb = StringBuffer('Registered Tasks / Jobs (${tasks.length}):\n');
          for (final t in tasks) {
            sb.writeln('• ${t['name']} [${t['cron'] ?? t['id']}] - Status: ${t['status']}');
          }
          return {'content': [{'type': 'text', 'text': sb.toString()}], 'isError': false};

        default:
          return {'content': [{'type': 'text', 'text': 'Unknown task tool: $name'}], 'isError': true};
      }
    } catch (e) {
      return {'content': [{'type': 'text', 'text': 'Task tool error: $e'}], 'isError': true};
    }
  }
}
