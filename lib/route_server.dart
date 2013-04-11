part of higgins_server;

final configURL = new UrlPattern('/config/');
final commandURL = new UrlPattern(r'/command/(\d+)/\$');
final buildsURL = new UrlPattern(r'/builds/(\d+)');
final buildURL = new UrlPattern(r'/build/');

Path _basePath;

_startRouteServer(Path basePath, String ip, int port) {
    _basePath = basePath;
    HttpServer.bind(ip, port).then((HttpServer server) {
      var router = new Router(server);
      router.serve(configURL).listen(serveConfig);
      router.serve(commandURL).listen(serveCommand);
      router.serve(buildsURL).listen(serveBuilds);
      router.serve(buildURL).listen(serveBuild);
      router.defaultStream.listen(serveStatic);
    });
}

void serveConfig(request) {
  _showConfig(request);
}

void serveCommand(request) {
  new CommandHandler().handler(request);
}

void serveBuilds(request) {
  String job = commandURL.parse(request.uri.path)[0];
  _getBuilds(request, job);
}

void serveBuild(request) {
  HttpResponse response = request.response;
  response..write("Request handled for build...")..close();
}

void serveStatic(request) {
  _staticFileHandler(_basePath, request);
}