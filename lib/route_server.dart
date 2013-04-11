part of higgins_server;

_startRouteServer(Path basePath, String ip, int port) {
    HttpServer.bind(ip, port).then((HttpServer server) {
      var router = new Router(server);
    });
}