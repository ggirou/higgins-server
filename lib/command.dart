part of higgins_server;

List<MessageBox> _commandIsolates = new List();

int runCommand(Command command) {
  IsolateSink sink = streamSpawnFunction(_runCommand);
  var mb = new MessageBox();
  sink.add([command, mb.sink]);
}

_runCommand() {
  stream.listen((List isolateArgs) {
    Command command = isolateArgs[0];
    IsolateSink output = isolateArgs[1];
    command.start().listen(output.add).onDone(output.close);
  });
}

Stream<String> getCommand(int isolateId) {
  _commandIsolates[isolateId].stream;
}

pipeCommandInto(int isolateId, StreamConsumer<String, dynamic> output) {
  // Quel est l'impact du broadcast en mémoire ?
  _commandIsolates[isolateId].stream.asBroadcastStream().pipe(output);
}

abstract class Command {
  Stream<String> start();
}

class BaseCommand extends Command {
  String executable;
  List<String> arguments;
  ProcessOptions options;
  
  BaseCommand(this.executable, this.arguments, [this.options]);
  
  Stream<String> start() {
    StreamController<String> output = new StreamController();
    
    output..add("\$ ")..add(executable)..add(" ")..add(arguments.join(" "))..add("\n");
    Process.start(executable, arguments, options).then((Process p) {
      StringDecoder decoder = new StringDecoder();
      p.stderr.transform(decoder).listen(output.add);
      p.stdout.transform(decoder).listen(output.add).onDone(output.close);
    });
    
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
      
      c.start()
      .listen(output.add)
      .onDone(completer.complete);
      
      return completer.future;
    }).then((_) => output.close());
    
    return output.stream;
  }
}

class GitCommand extends BaseCommand {
  GitCommand.clone(String gitRepoUrl, {String gitExecutablePath: "git"}) :
    super(gitExecutablePath, ["clone", gitRepoUrl]);
}
