part of higgins_server;

class CommandHandler {
  final String buildId;
  CommandHandler(this.buildId);
  
  handler(HttpRequest request) {
    Stream<String> commandStream = null;
    
    commandStream = consumeCommand(buildId);

    if(commandStream != null) {
      print("200 - ${request.uri}");
      
      HttpResponse response = request.response;
      response.headers
      ..set(HttpHeaders.CONTENT_TYPE, 'text/event-stream')
      ..set(HttpHeaders.CACHE_CONTROL, 'no-cache')
      ..set(HttpHeaders.CONNECTION, 'keep-alive');
      
      // TODO Hack: never retry
//      response.writeString("retry: 999999");
      commandStream.transform(new LineTransformer())
        .transform(new StreamTransformer<String, String>(handleData: _eventSourceTransformer))
        .transform(new StringEncoder()).pipe(response);
    } else {
      _send404(request);
    }
  }
  
  _eventSourceTransformer(String value, EventSink<String> sink) {
    sink.add("data:");
    sink.add(value);
    sink.add("\n\n");
  }
}
