part of higgins_server;

Configuration _config;
BuildDao _buildDao;
GitRunner _gitRunner;

_send404(HttpRequest request, HttpResponse response, String filePath) {
  print("404 - ${request.uri} - $filePath");
  response.statusCode = HttpStatus.NOT_FOUND;
  response.close();
}

startServer(Configuration configuration) {
  _config = configuration;
  Path currentPath = new Path(new File(new Options().script).directorySync().path);
  Path basePath = currentPath.append(_config.basePath).canonicalize();
  print("Lauching Web Server, rendering files from $basePath");
  _startServer(basePath, _config.host, _config.port);
  print("Server running...");
  initMongo(_config.mongoDbUri);
  _buildDao = new BuildDao();
  _gitRunner = new GitRunner(_config.gitExecutablePath);
}

_startServer(Path basePath, String ip, int port) {
  HttpServer.bind(ip, port).then((HttpServer server) {
    print('Server started on: http://$ip:$port');
    var configPathMatching = (HttpRequest request) => request.uri.path.startsWith("/config/");
    var commandPathMatching = (HttpRequest request) => request.uri.path.startsWith("/command/");
    var buildPathMatching = (HttpRequest request) => request.uri.path.startsWith("/builds/");
    server.listen((HttpRequest request) {
      var path = request.uri.path;
      print("${request.method} - ${path}");

      if(path.startsWith("/config/")) {
        _showConfig(request);
      } else if(path.startsWith("/command/")) {
        // String build = path.substring(9);
        new CommandHandler().handler(request);
      } else if(path.startsWith("/builds/")) {
        String job = path.substring(8);
        _getBuilds(request, job);
      } else if(path.startsWith("/build/")) {
        _readAsString(request).then((String data) {
          var jsonData = JSON.parse(data);
          
          HttpResponse response = request.response;
          response..write(JSON.stringify({"build_id": "123"}))
          ..close();

          _gitRunner.gitClone(jsonData["git_url"]);
        });
      } else {
        _staticFileHandler(basePath, request);
      }
    });
  }, onError: (error) => print("Failed to start server: $error"));
}

Future<String> _readAsString(HttpRequest request) {
  // WTF!!!
  Completer completer = new Completer();
  StringBuffer s = new StringBuffer(); 
  request.transform(new StringDecoder())
    .listen((String value) => s.write(value))
    ..onDone(() => completer.complete(s.toString()))
    ..onError((error) => completer.completeError(error.error, error.stackTrace));
  return completer.future;
}

void _showConfig(HttpRequest request) {
  var data = {
              "host": _config.host,
              "port": _config.port,
              "basePath": _config.basePath
  };
  
  HttpResponse response = request.response;
  response.write(data.toString());
  response.close();
}

void _getBuilds(HttpRequest request, String job) {
  var writeResponse = (List builds) => request.response
      ..write(builds.toString())
      ..close();
  
  if(job.isEmpty){
    _buildDao.all().then(writeResponse);
  } else {
    _buildDao.findByJob(job).then(writeResponse);
  }
}

void _staticFileHandler(Path basePath, HttpRequest request) {
  HttpResponse response = request.response;
  final String file= request.uri.path == '/' ? '/index.html' : request.uri.path;
  
  String filePath = basePath.append(file).canonicalize().toNativePath();
  print(filePath);
  if(!filePath.startsWith(basePath.toNativePath())){
    _send404(request, response, filePath);
  } else {
    final File file = new File(filePath);
    file.exists().then((bool found) {
      if (found) {
        print("200 - ${request.uri.path} - $filePath");
        file.openRead().pipe(response);
      } else {
        _send404(request, response, filePath);
      }
    });
  }
}

