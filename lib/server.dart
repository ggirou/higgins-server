part of higgins_server;

Configuration _config;
BuildDao _buildDao;

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
        var data = {
                    "host": _config.host,
                    "port": _config.port,
                    "basePath": _config.basePath
        };
        
        HttpResponse response = request.response;
        response.addString(data.toString());
        response.close();
      } else if(path.startsWith("/command/")) {
        new CommandHandler().handler(request);
      } else if(path.startsWith("/builds/")) {
        String job = path.substring(8);
        if(path.isEmpty){
          _buildDao.all().then((List builds) => request.response..addString(builds.toString())
                                                               ..close());
        } else {
          _buildDao.findByJob(job).then((List builds) => request.response..addString(builds.toString())
                                                                        ..close());
        }
      } else {
        HttpResponse response = request.response;
        final String file= path == '/' ? '/index.html' : path;
        
        String filePath = basePath.append(file).canonicalize().toNativePath();
        print(filePath);
        if(!filePath.startsWith(basePath.toNativePath())){
          _send404(request, response, filePath);
        } else {
          final File file = new File(filePath);
          file.exists().then((bool found) {
            if (found) {
              print("200 - ${path} - $filePath");
              file.openRead().pipe(response);
            } else {
              _send404(request, response, filePath);
            }
          });
        }
      }
    });
  }, onError: (error) => print("Failed to start server: $error"));
}

