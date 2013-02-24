part of higgins_server;

class CommandHandler {
  handler(HttpRequest request, HttpResponse response) {
    response.headers
      ..set(HttpHeaders.CONTENT_TYPE, 'text/event-stream')
      ..set(HttpHeaders.CACHE_CONTROL, 'no-cache')
      ..set(HttpHeaders.CONNECTION, 'keep-alive');

    ProcessOptions processOptions = new ProcessOptions();
    Process.start('ping', ['-c', '10', 'google.fr'], processOptions)
    .then((Process p) {
      print("ping -c 10 google.fr");
      p.stdout.pipe(response.outputStream);
    });
  }
}

