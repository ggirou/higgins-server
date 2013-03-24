part of higgins_server;

class CommandHandler {
  handler(HttpRequest request) {
    HttpResponse response = request.response;
    response.headers
    ..set(HttpHeaders.CONTENT_TYPE, 'text/event-stream')
    ..set(HttpHeaders.CACHE_CONTROL, 'no-cache')
    ..set(HttpHeaders.CONNECTION, 'keep-alive');
    
    runSocketCommand(response);
  }
}

runSocketCommand(StreamConsumer<List<int>, dynamic> output) {
  IsolateSink sink = streamSpawnFunction(_runSocketCommand);
  var mb = new MessageBox();
  sink.add(mb.sink);
  mb.stream.transform(new StringEncoder()).pipe(output);
}

_runSocketCommand() {
  stream.listen((IsolateSink output) => processCommand().listen(output.add).onDone(output.close));
}

Stream<String> processCommand() {
  StreamController<String> output = new StreamController();
  
  ProcessOptions processOptions = new ProcessOptions();
  Process.start('ping', ['-c', '10', 'google.fr'], processOptions)
  .then((Process p) {
    print("ping -c 10 google.fr");
    output.add("ping -c 10 google.fr");
    
    var eventSourceTransformer = (String value, StreamSink<String> sink) {
      sink.add("data:");
      sink.add(value);
      sink.add("\n\n");
      print(value);
    };
    
    var stdout = p.stdout
        .transform(new StringDecoder()).transform(new LineTransformer())
        .transform(new StreamTransformer<String, String>(handleData: eventSourceTransformer));
    var stderr = p.stderr
        .transform(new StringDecoder()).transform(new LineTransformer())
        .transform(new StreamTransformer<String, String>(handleData: eventSourceTransformer));
    
    stderr.listen(output.add);
    stdout.listen(output.add).onDone(output.close);
  });
  
  return output.stream;
}
