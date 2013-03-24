import 'dart:io';
import 'lib/higgins_server.dart';

main() {
  List<String> args = new Options().arguments;
  if(args.length == 1) {
    File f = new File(args[0]);
    if(f.existsSync()) {
      f.readAsString().then((json) {
        configuration = new Configuration.fromFile(json);
        startServer();
      });
      return;
    } else {
      print("$f doesn't exists.");
    }
  }
  print("Please give the right arguments");
  print("dart main.dart conf.json");
}
