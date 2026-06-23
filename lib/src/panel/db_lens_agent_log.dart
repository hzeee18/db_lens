import 'dart:convert';
import 'dart:io';

/// Debug instrumentation — session 2a097b. Hapus setelah verifikasi fix.
void dbLensAgentLog({
  required String location,
  required String message,
  required Map<String, dynamic> data,
  String hypothesisId = '',
  String runId = 'pre-fix',
}) {
  // #region agent log
  final payload = <String, dynamic>{
    'sessionId': '2a097b',
    'runId': runId,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final body = jsonEncode(payload);
  final paths = [
  r'c:\Users\99999153\Documents\development\code\db_lens\debug-2a097b.log',
    'debug-2a097b.log',
  ];
  for (final path in paths) {
    try {
      File(path).writeAsStringSync('$body\n', mode: FileMode.append);
      break;
    } catch (_) {}
  }
  try {
    final client = HttpClient();
    client
        .postUrl(
          Uri.parse(
            'http://127.0.0.1:7760/ingest/0aa8b52f-e6fd-43b0-99aa-3608326b1c81',
          ),
        )
        .then((req) {
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('X-Debug-Session-Id', '2a097b');
      req.write(body);
      return req.close();
    })
        .then((_) => client.close())
        .catchError((_) => client.close(force: true));
  } catch (_) {}
  // #endregion
}
