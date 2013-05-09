import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:unittest/vm_config.dart';
import "db_access_int_test.dart" as db_test;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';
  db_test.main();
}