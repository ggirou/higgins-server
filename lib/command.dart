part of higgins_server;

Map<String, MessageBox> _commandIsolates = new Map();

runCommand(String buildId, Command command) {
  IsolateSink sink = streamSpawnFunction(_runCommand);
  var mb = new MessageBox();
  sink.add([command, mb.sink]);
  sink.close();
  _commandIsolates[buildId] = mb;
}

_runCommand() {
  stream.listen((List isolateArgs) {
    Command command = isolateArgs[0];
    IsolateSink output = isolateArgs[1];
    command.start().listen(output.add, onError: output.addError, onDone: output.close);
  });
}

Stream<String> getCommand(String buildId) => 
    _commandIsolates.containsKey(buildId) ? _commandIsolates[buildId].stream.asBroadcastStream() : null;

Stream<String> consumeCommand(String buildId) =>
  _commandIsolates.containsKey(buildId) ? _commandIsolates.remove(buildId).stream : null;

abstract class Command {
  Stream<String> start();
}

class BaseCommand extends Command {
  final String executable;
  List<String> arguments;
  ProcessOptions options;
  
  BaseCommand(this.executable, [arguments, options]) :
    this.arguments = ?arguments ? new List.from(arguments) : new List(),
    this.options = ?options ? options : new ProcessOptions();
  
  Stream<String> start() {
    StreamController<String> output = new StreamController();
    
    output..add("\$ ")..add(executable)..add(" ")..add(arguments.join(" "))..add("\n");
    Process.start(executable, arguments, options).then((Process p) {
      StringDecoder decoder = new StringDecoder();
      p.stderr.transform(decoder).listen(output.add, onError: output.addError);
      p.stdout.transform(decoder).listen(output.add, onError: output.addError, onDone: output.close);
    }).catchError(output.addError);
    
    return output.stream;
  }
  
  String get workingDirectory => options.workingDirectory;
  set workingDirectory(String  value) => options.workingDirectory = value;
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
    if(?destinationDir) {
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
