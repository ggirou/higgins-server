part of higgins_server;

final configURL = new UrlPattern('/config/');
final commandURL = new UrlPattern(r'/command/([0-9a-fA-F]+)/');
// TODO: add a slash at the end
final buildsURL = new UrlPattern(r'/builds/(\d+)');
final buildURL = new UrlPattern(r'/build/');

JobQuery _jobQuery;
BuildOutputQuery _buildOutput;
String _basePath;

_send404(HttpRequest request, [String filePath = ""]) {
  print("404 - ${request.uri} - $filePath");
  request.response.statusCode = HttpStatus.NOT_FOUND;
  request.response.close();
}

startServer() {
  final basePath = path.join(path.current, configuration.basePath);
  print("Lauching Web Server, rendering files from $basePath");
  _startRouteServer(basePath, configuration.host, configuration.port);
  print("Server running...");
  initMongo(configuration.mongoDbUri);
  _jobQuery = new JobQuery();
  _buildOutput = new BuildOutputQuery();
}

_startRouteServer(String basePath, String ip, int port) {
    _basePath = basePath;
    HttpServer.bind(ip, port).then((HttpServer server) {
      print('Server started on: http://$ip:$port');
      var router = new Router(server);
      router.serve(configURL).listen(serveConfig);
      router.serve(commandURL).listen(serveCommand);
      router.serve(buildsURL).listen(serveBuilds);
      router.serve(buildURL).listen(serveBuild);
      router.defaultStream.listen(serveStatic);
    }, onError: (error) => print("Failed to start server: $error"));
}

void serveConfig(HttpRequest request) {
  var data = _getConfig();
  HttpResponse response = request.response;
  response.write(data.toString());
  response.close();
}

void serveCommand(HttpRequest request) {
  String buildId = commandURL.parse(request.uri.path)[0];
  new CommandHandler(buildId).handler(request);
}

void serveBuilds(HttpRequest request) {
  var writeResponse = (List builds) => request.response
      ..write(builds.toString())
      ..close();
  
    String job = commandURL.parse(request.uri.path)[0];
    _getBuilds(job).then(writeResponse);
  }

void serveBuild(HttpRequest request) {
  _readAsString(request).then((String data) {
      triggerBuild(data).then((String buildResult){
        HttpResponse response = request.response;
        response..write(buildResult)
        ..close();
    });
  });
}

void serveStatic(HttpRequest request) {
  HttpResponse response = request.response;
  final String file = request.uri.path == '/' ? 'index.html' : request.uri.path.substring(1);
  //final filePath = _basePath+file;
  // TODO join fail ???? => not absolute
  final filePath = path.join(_basePath, file);
  print(filePath);
  if(!filePath.startsWith(_basePath)){
    _send404(request, filePath);
 } else {
    final File file = new File(filePath);
    file.exists().then((bool found) {
      if (found) {
        print("200 - ${request.uri.path} - $filePath");
        file.openRead().pipe(response);
      } else {
        _send404(request, filePath);
      }
    });
  }
}

Future<String> triggerBuild(String data){
  return new Future(() {
    var jsonData = JSON.parse(data);
    
//    var buildId = new Random(new DateTime.now().millisecondsSinceEpoch).nextInt(10000);
    String buildId = BuildOutput.generateId().toHexString();
    String workingDirectory = "${configuration.buildDir}/$buildId/";
    var build = new BuildCommand.fromGit(workingDirectory, jsonData["git_url"], configuration: configuration);
    runCommand(buildId, build);
    
    return JSON.stringify({"build_id": buildId});
  });
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

_getConfig() {
  return {
              "host": configuration.host,
              "port": configuration.port,
              "basePath": configuration.basePath,
              "buildDir": configuration.buildDir,
              "gitExecutablePath": configuration.gitExecutablePath,
              "pubExecutablePath": configuration.pubExecutablePath
  };
}

Future _getBuilds(String job) {
  if(job.isEmpty){
    return _jobQuery.all();
  } else {
    return _jobQuery.findByJob(job);
  }
}

