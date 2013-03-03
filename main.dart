import 'dart:io';
import 'lib/higgins_server.dart';

Configuration config;

_send404(HttpRequest request, HttpResponse response, String filePath) {
  print("404 - ${request.uri} - $filePath");
  response.statusCode = HttpStatus.NOT_FOUND;
  response.close();
}

startServer(Path basePath, String ip, int port) {
  HttpServer.bind(ip, port).then((HttpServer server) {
    print('Server started on: http://$ip:$port');
    var configPathMatching = (HttpRequest request) => request.uri.path.startsWith("/config/");
    var commandPathMatching = (HttpRequest request) => request.uri.path.startsWith("/command/");
    server.listen((HttpRequest request) {
      var path = request.uri.path;
      print("${request.method} - ${path}");

      if(path.startsWith("/config/")) {
        var data = {
                    "host": config.host,
                    "port": config.port,
                    "basePath": config.basePath
        };
        
        HttpResponse response = request.response;
        response.addString(data.toString());
        response.close();
      } else if(path.startsWith("/command/")) {
        new CommandHandler().handler(request);
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

main() {
  List<String> args = new Options().arguments;
  if(args.length == 1) {
    File f = new File(args[0]);
    if(f.existsSync()) {
      f.readAsString().then((json) {
        config = new Configuration.fromFile(json);

        Path currentPath = new Path(new File(new Options().script).directorySync().path);
        Path basePath = currentPath.append(config.basePath).canonicalize();
        print("Lauching Web Server, rendering files from $basePath");
        startServer(basePath, config.host, config.port);
        print("Server running...");
      });
      return;
    } else {
      print("$f doesn't exists.");
    }
  }
  print("Please give the right arguments");
  print("dart main.dart conf.json");
}

void gitClone(String gitRepoUrl){
  List<String> args = new List<String>();
  args.addAll(["clone", gitRepoUrl]);
  executeGitCommand(args);
}

void executeGitCommand(List<String> args) {
  ProcessOptions processOptions = new ProcessOptions();
  Process.run('git', args, processOptions)
      .then((ProcessResult pr) {
        if(pr.exitCode == 0){
          print("Git clone success");
        }else {
          print("Git clone failed with error code ${pr.exitCode}, ${pr.stderr}");
        }
      });
}
