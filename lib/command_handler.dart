part of higgins_server;

class CommandHandler {
  static final RegExp _paramRegExp = new RegExp("/(\\d+)/\$");
  
  handler(HttpRequest request) {
    Stream<String> commandStream = null;
    
    if(_paramRegExp.hasMatch(request.uri.path)) {
      int buildId = int.parse(_paramRegExp.firstMatch(request.uri.path)[1]);
      commandStream = consumeCommand(buildId);
    }

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
  
  _eventSourceTransformer(String value, StreamSink<String> sink) {
    sink.add("data:");
    sink.add(value);
    sink.add("\n\n");
    // TODO: remove
    print(value);
  }
}
