// Serves docs/packs on a local port, to try story-season downloads in a debug
// build without publishing anything.
//
//   dart run tool/serve_packs.dart [port]
//
// An Android emulator reaches the computer at 10.0.2.2, or run
// `adb reverse tcp:8080 tcp:8080` and use localhost. Then run the app with
//   --dart-define=CONTENT_URL=http://localhost:8080/
// (plain http is only accepted by debug builds).
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? 8080 : int.parse(args.first);
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Serving docs/packs on http://localhost:$port/ (Ctrl+C to stop)');
  await for (final request in server) {
    final name = request.uri.pathSegments.isEmpty ? '' : request.uri.pathSegments.last;
    final file = File('docs/packs/$name');
    if (RegExp(r'^[a-z0-9_]+\.json$').hasMatch(name) && file.existsSync()) {
      request.response.headers.contentType = ContentType.json;
      request.response.add(file.readAsBytesSync());
      stdout.writeln('200 $name');
    } else {
      request.response.statusCode = HttpStatus.notFound;
      stdout.writeln('404 ${request.uri.path}');
    }
    await request.response.close();
  }
}
