import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import "configuration_test.dart" as configuration_test;
import "command_test.dart" as command_test;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';
  configuration_test.main();
  command_test.main();
}