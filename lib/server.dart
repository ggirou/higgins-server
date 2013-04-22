part of higgins_server;

JobQuery _jobQuery;
BuildOutputQuery _buildOutput;

_send404(HttpRequest request, [String filePath = ""]) {
  print("404 - ${request.uri} - $filePath");
  request.response.statusCode = HttpStatus.NOT_FOUND;
  request.response.close();
}

startServer() {
  Path currentPath = new Path(new File(new Options().script).directorySync().path);
  Path basePath = currentPath.append(configuration.basePath).canonicalize();
  print("Lauching Web Server, rendering files from $basePath");
  _startRouteServer(basePath, configuration.host, configuration.port);
  print("Server running...");
  initMongo(configuration.mongoDbUri);
  _jobQuery = new JobQuery();
  _buildOutput = new BuildOutputQuery();
}

final configURL = new UrlPattern('/config/');
final commandURL = new UrlPattern(r'/command/(\d+)/\$');
final buildsURL = new UrlPattern(r'/builds/(\d+)');
final buildURL = new UrlPattern(r'/build/');

Path _basePath;

_startRouteServer(Path basePath, String ip, int port) {
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

void serveConfig(request) {
  var data = _getConfig();
  HttpResponse response = request.response;
  response.write(data.toString());
  response.close();
}

void serveCommand(request) {
  new CommandHandler().handler(request);
}

void serveBuilds(request) {
  String job = commandURL.parse(request.uri.path)[0];
  _getBuilds(request, job);
}

void serveBuild(request) {
  _build(request);
}

void serveStatic(request) {
  _staticFileHandler(_basePath, request);
}

void _build(HttpRequest request) {
  _readAsString(request).then((String data) {
      triggerBuild(data).then((String buildResult){
        HttpResponse response = request.response;
        response..write(buildResult)
        ..close();
    });
  });
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
  var data = {
              "host": configuration.host,
              "port": configuration.port,
              "basePath": configuration.basePath,
              "buildDir": configuration.buildDir,
              "gitExecutablePath": configuration.gitExecutablePath,
              "pubExecutablePath": configuration.pubExecutablePath
  };
  return data;
}

void _getBuilds(HttpRequest request, String job) {
  var writeResponse = (List builds) => request.response
      ..write(builds.toString())
      ..close();
  
  if(job.isEmpty){
    _jobQuery.all().then(writeResponse);
  } else {
    _jobQuery.findByJob(job).then(writeResponse);
  }
}

void _staticFileHandler(Path basePath, HttpRequest request) {
  HttpResponse response = request.response;
  final String file= request.uri.path == '/' ? '/index.html' : request.uri.path;
  
  String filePath = basePath.append(file).canonicalize().toNativePath();
  print(filePath);
  if(!filePath.startsWith(basePath.toNativePath())){
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

