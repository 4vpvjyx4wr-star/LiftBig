import 'dart:convert';
import 'dart:io';

/// Debug-session logger. Writes one NDJSON line locally and posts the same
/// payload to the session ingest server. Failures are ignored.
void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  String runId = 'pre-fix',
  Map<String, Object?> data = const {},
}) {
  final payload = <String, Object?>{
    'sessionId': 'e2e030',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = jsonEncode(payload);
  try {
    stderr.writeln('DBG-e2e030 $line');
  } catch (_) {}
  try {
    File('/Users/jtiralongo/Documents/GitHub/LiftBig/.cursor/debug-e2e030.log')
        .writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  } catch (_) {}
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 400);
    client
        .postUrl(
          Uri.parse(
            'http://127.0.0.1:7358/ingest/624dc5b8-e11a-4cc6-b4f7-085738ce39ae',
          ),
        )
        .then((request) {
          request.headers.set('Content-Type', 'application/json');
          request.headers.set('X-Debug-Session-Id', 'e2e030');
          request.add(utf8.encode(line));
          return request.close();
        })
        .then((response) => response.drain<void>())
        .catchError((_) {})
        .whenComplete(client.close);
  } catch (_) {}
}
