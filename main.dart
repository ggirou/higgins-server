import 'dart:io';
import 'lib/higgins_server.dart';

Configuration config;

_send404(HttpRequest request, HttpResponse response, String filePath) {
  print("404 - ${request.path} - $filePath");
  response.statusCode = HttpStatus.NOT_FOUND;
  response.outputStream.close();
}

startServer(Path basePath, String ip, int port) {
  var server = new HttpServer();
  server.listen(ip, port);
  print('Server started on: http://$ip:$port');
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    print("${request.method} - ${request.path}");
    final String path = request.path == '/' ? '/index.html' : request.path;
    
    String filePath = basePath.append(path).canonicalize().toNativePath();
    print(filePath);
    if(!filePath.startsWith(basePath.toNativePath())){
      _send404(request, response, filePath);
    } else {
      final File file = new File(filePath);
      file.exists().then((bool found) {
        if (found) {
          print("200 - ${request.path} - $filePath");
          file.openInputStream().pipe(response.outputStream);
        } else {
          _send404(request, response, filePath);
        }
      });
    }
  };
  server.addRequestHandler((request) => request.path.startsWith("/config/"), (HttpRequest request, HttpResponse response) {
    var data = {
      "host": config.host,
      "port": config.port,
      "basePath": config.basePath
    };
    
    response.outputStream.writeString(data.toString());
    response.outputStream.close();
  });
  server.addRequestHandler((request) => request.path.startsWith("/command/"), new CommandHandler().handler); 
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
