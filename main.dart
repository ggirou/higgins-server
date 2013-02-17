import 'dart:io';
import 'lib/higgins_server.dart';

Configuration config;

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
  server.addRequestHandler((request) => request.path.startsWith("config"), (HttpRequest request, HttpResponse response) {
    
  });
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
        String path = basePath.toNativePath();
        print("Lauching Web Server, rendering files from $path");
        startServer(path, config.host, config.port);
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
