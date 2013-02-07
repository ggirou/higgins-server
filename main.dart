import 'dart:io';

_send404(HttpResponse response) {
  response.statusCode = HttpStatus.NOT_FOUND;
  response.outputStream.close();
}

startServer(String basePath, String ip, int port) {
  var server = new HttpServer();
  server.listen(ip, port);
  print('Server started on: http://$ip:$port');
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    print("Request: ${request.path}");
    final String path = request.path == '/' ? '/index.html' : request.path;
    final File file = new File('${basePath}${path}');
    print("File: $file");
    file.exists().then((bool found) {
      if (found) {
        file.fullPath().then((String fullPath) {
          if (!fullPath.startsWith(basePath)) {
            _send404(response);
          } else {
            file.openInputStream().pipe(response.outputStream);
          }
        });
      } else {
        _send404(response);
      }
    });
  };
}

main() {
  List<String> args = new Options().arguments;
  if(args.length == 3) {
    Path currentPath = new Path(new File(new Options().script).directorySync().path);
    Path basePath = currentPath.append(args[0]).canonicalize();
    String path = basePath.toNativePath();
    print("Lauching Web Server, rendering files from $path");
    startServer(path, args[1], int.parse(args[2], onError: (s) => 80));
    print("Server running...");
  } else {
    print("Please give the right arguments");
    print("dart main.dart BASEPATH IP PORT");
  }
}
