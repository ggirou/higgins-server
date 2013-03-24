library command_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/matcher.dart' as m;

import 'package:higgins_server/higgins_server.dart';

class TestCommand extends Command {
  List<String> data;
  Duration period;
  
  TestCommand(this.data, this.period);
  
  Stream<String> start() {
    StreamController<String> controller = new StreamController();
    int i = 0;
    new Timer.periodic(period, (Timer timer) {
      if(i >= data.length) {
        timer.cancel();
        controller.close();
      } else {
        controller.add(data[i++]);
      }
    });
    return controller.stream;
  }
}

main() {
  group('Command', () {
    test('execute base command: echo', () {
      String executable = "echo";
      List<String> arguments = ["A", "towel,", "it", "says"];
      String expected = "\$ echo A towel, it says\nA towel, it says\n";
      
      Stream<String> output = new BaseCommand(executable, arguments).start();
      
      output.reduce(new StringBuffer(), (sb, string) => sb..write(string)).then(expectAsync1((result) {
        expect(result.toString(), equals(expected));
      }));
    });
    
    test('execute in sequence', () {
      List<Command> commands = [
                                new TestCommand(["A ", "towel, ", "it ", "says, "], new Duration(milliseconds: 100)),
                                new TestCommand(["is ", "about ", "the ", "most ", "massively ", "useful ", "thing "], new Duration(milliseconds: 50)),
                                new TestCommand(["an ", "interstellar ", "hitch ", "hiker ", "can ", "have."], new Duration(milliseconds: 25))
                                ];
      String expected = "A towel, it says, is about the most massively useful thing an interstellar hitch hiker can have.";
      
      Stream<String> output = new CommandsSequence.from(commands).start();
      
      output.reduce(new StringBuffer(), (sb, string) => sb..write(string)).then(expectAsync1((result) {
        expect(result.toString(), equals(expected));
      }));
    });
  });
}
