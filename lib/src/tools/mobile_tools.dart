import '../bridge/push_service.dart';

class MobileTools {
  final TealKitMobileBridge bridge;

  MobileTools(this.bridge);

  List<Map<String, dynamic>> get definitions => [
        {
          'name': 'tealkit_send_mobile_alert',
          'description':
              'Sends an instant push notification to the user TealKit mobile app (Android / iOS).',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'title': {
                'type': 'string',
                'description': 'Brief notification headline (e.g. Build Finished, Action Required)',
              },
              'message': {
                'type': 'string',
                'description': 'Notification body text with details or summary',
              },
              'priority': {
                'type': 'string',
                'description': 'Priority level: low, normal, high, urgent (default: normal)',
                'default': 'normal',
              },
            },
            'required': ['title', 'message'],
          },
        },
        {
          'name': 'tealkit_request_mobile_approval',
          'description':
              'Sends an interactive approval prompt to the user smartphone and waits until the user taps Approve or Reject.',
          'inputSchema': {
            'type': 'object',
            'properties': {
              'title': {
                'type': 'string',
                'description': 'Title of the action requiring confirmation (e.g. Deploy to Production?)',
              },
              'summary': {
                'type': 'string',
                'description': 'Summary of proposed changes or commands about to be run',
              },
              'details': {
                'type': 'string',
                'description': 'Optional diff snippet or detailed command line',
              },
              'timeout_seconds': {
                'type': 'integer',
                'description': 'How long to wait for user mobile response before timing out (default: 180s)',
                'default': 180,
              },
            },
            'required': ['title', 'summary'],
          },
        },
      ];

  Future<Map<String, dynamic>> execute(String name, Map<String, dynamic> arguments) async {
    try {
      switch (name) {
        case 'tealkit_send_mobile_alert':
          final title = arguments['title'] as String? ?? 'TealKit Alert';
          final message = arguments['message'] as String? ?? '';
          final priority = arguments['priority'] as String? ?? 'normal';

          final res = await bridge.sendAlert(
            title: title,
            message: message,
            priority: priority,
          );

          if (res['success'] == true) {
            return {'content': [{'type': 'text', 'text': 'Mobile alert "$title" sent successfully to user device.'}], 'isError': false};
          } else {
            return {'content': [{'type': 'text', 'text': 'Failed to send mobile alert: ${res['error']}'}], 'isError': true};
          }

        case 'tealkit_request_mobile_approval':
          final title = arguments['title'] as String? ?? 'Approval Request';
          final summary = arguments['summary'] as String? ?? '';
          final details = arguments['details'] as String?;
          final timeout = (arguments['timeout_seconds'] as num?)?.toInt() ?? 180;

          final res = await bridge.requestApproval(
            title: title,
            summary: summary,
            details: details,
            timeoutSeconds: timeout,
          );

          if (res['approved'] == true) {
            return {'content': [{'type': 'text', 'text': 'APPROVED: User confirmed action on mobile device (${res['user_decision'] ?? 'Approved'}).'}], 'isError': false};
          } else {
            return {'content': [{'type': 'text', 'text': 'REJECTED / NOT APPROVED: ${res['error'] ?? 'User rejected the request.'}'}], 'isError': true};
          }

        default:
          return {'content': [{'type': 'text', 'text': 'Unknown mobile tool: $name'}], 'isError': true};
      }
    } catch (e) {
      return {'content': [{'type': 'text', 'text': 'Mobile tool error: $e'}], 'isError': true};
    }
  }
}
