part of higgins_server;

Map<String, Stream> _commandIsolates = new Map();

class _RunCommandArgs {
  final IsolateSink output;
  final Configuration configuration;
  final String buildId;
  final Command command;
  _RunCommandArgs(this.output, this.configuration, this.buildId, this.command);
}

runCommand(String buildId, Command command) {
  IsolateSink sink = streamSpawnFunction(_runCommand);
  var mb = new MessageBox();
  sink..add([new _RunCommandArgs(mb.sink, configuration, buildId, command)])
      ..close();
  _commandIsolates[buildId] = mb.stream.asBroadcastStream();
}

_runCommand() {
  stream.listen((List args) {
    _RunCommandArgs commandArgs = args[0];
    IsolateSink output = commandArgs.output;
    
    Stream commandStream = commandArgs.command.start().asBroadcastStream();
    commandStream.listen(output.add, onError: output.addError, onDone: output.close);
    // For debug purpose
    commandStream.listen(stdout.write, onError: stdout.addError, onDone: () => stdout.write("Finished!"));
    
    StringBuffer reportBuffer = new StringBuffer();
    commandStream.listen(reportBuffer.write, onDone: () {
      initMongo(commandArgs.configuration.mongoDbUri).then((_) {
        var report = new BuildOutput.fromData(reportBuffer.toString());
        print("\n**********************\n${report.data}\n**********************\n");
        report.saveWithId(new ObjectId.fromHexString(commandArgs.buildId)).then((_) => closeMongo);
      });
    }); 
  });
}

Stream<String> getCommand(String buildId) => 
  _commandIsolates.containsKey(buildId) ? _commandIsolates[buildId] : null;

Stream<String> consumeCommand(String buildId) =>
  _commandIsolates.containsKey(buildId) ? _commandIsolates.remove(buildId) : null;

abstract class Command {
  Stream<String> start();
}

class BaseCommand extends Command {
  final String executable;
  List<String> arguments;
  String workingDirectory;
  
  BaseCommand(this.executable, [arguments, this.workingDirectory]) :
    this.arguments = arguments ? new List.from(arguments) : new List();
    
    Stream<String> start() {
      StreamController<String> output = new StreamController();
      
      output..add("\$ ")..add(executable)..add(" ")..add(arguments.join(" "))..add("\n");
      Process.start(executable, arguments, workingDirectory: workingDirectory).then((Process p) {
        StringDecoder decoder = new StringDecoder();
        p.stderr.transform(decoder).listen(output.add, onError: output.addError);
        p.stdout.transform(decoder).listen(output.add, onError: output.addError, onDone: output.close);
      }).catchError(output.addError);
      
      return output.stream;
    }
    
}

class CommandsSequence extends Command {
  final List<Command> commands;
  
  CommandsSequence() : this.commands = new List();
  CommandsSequence.from(Iterable<Command> commands) : this.commands = new List.from(commands);
  
  Stream<String> start() {
    StreamController<String> output = new StreamController();
    
    Future.forEach(commands, (Command c) {
      Completer completer = new Completer(); 
      
      c.start().listen(output.add, onError: completer.completeError, onDone: completer.complete);
      
      return completer.future;
    }).catchError(output.addError).whenComplete(output.close);
    
    return output.stream;
  }
}

class GitCommand extends BaseCommand {
  GitCommand.clone(String gitRepoUrl, {String gitExecutablePath: "git", String destinationDir}) :
    super(gitExecutablePath, ["clone", gitRepoUrl]) {
    if(destinationDir != null) {
      arguments.add(destinationDir);
    }
  }
}

class PubCommand extends BaseCommand {
  PubCommand.install({String pubExecutablePath: "pub"}) :
    super(pubExecutablePath, ["install"]);
}

class BuildCommand extends CommandsSequence {
  String workingDirectory;
  
  BuildCommand.fromGit(String workingDirectory, String gitRepoUrl, {Configuration configuration: const Configuration()}) : 
    super.from([new GitCommand.clone(gitRepoUrl, 
        gitExecutablePath: configuration.gitExecutablePath, 
        destinationDir: workingDirectory)..workingDirectory = workingDirectory, 
        new PubCommand.install(pubExecutablePath: configuration.pubExecutablePath)..workingDirectory = workingDirectory]),
        this.workingDirectory = workingDirectory {
  }
  
  Stream<String> start() {
    StreamController<String> output = new StreamController();
    new Directory(workingDirectory).create(recursive: true)
    .then((_) => super.start().listen(output.add, onError: output.addError, onDone: output.close))
    .catchError(output.addError);
    return output.stream;
  }
}
