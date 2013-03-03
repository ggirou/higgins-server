part of higgins_server;

class CommandHandler {
  handler(HttpRequest request) {
    HttpResponse response = request.response;
    response.headers
      ..set(HttpHeaders.CONTENT_TYPE, 'text/event-stream')
      ..set(HttpHeaders.CACHE_CONTROL, 'no-cache')
      ..set(HttpHeaders.CONNECTION, 'keep-alive');

    ProcessOptions processOptions = new ProcessOptions();
    Process.start('ping', ['-c', '10', 'google.fr'], processOptions)
    .then((Process p) {
      print("ping -c 10 google.fr");
      var lineDecoder = new LineTransformer().bind(new StringDecoder().bind(p.stdout));
      lineDecoder = lineDecoder.transform(new StreamTransformer<String, String>(
        handleData: (String value, StreamSink<String> sink) {
          sink.add("data:");
          sink.add(value);
          sink.add("\n\n");
        }));
        new StringEncoder().bind(lineDecoder).pipe(response);
    });
  }
}

