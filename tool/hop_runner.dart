import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';
import '../test/test_runner.dart' as test_console;
import '../test/test_db_runner.dart' as test_db_console;

void main() {
  // Unit Test
  addTask('test', createUnitTestTask(test_console.testCore));
  addTask('db_test', createUnitTestTask(test_db_console.testCore));  
  
  //
  // Analyzer
  //
  addTask('analyze_libs', createAnalyzerTask(_getLibs));
  
  //
  // Dart2js
  //
  //addTask('dart2js', createDart2JsTask(['web/higgins.dart'],
  //    minify: true, liveTypeAnalysis: true, rejectDeprecatedFeatures: true));

  runHop();
}


Future<List<String>> _getLibs() {
  return new Directory('lib').list()
      .where((FileSystemEntity fse) => fse is File)
      .map((File file) => file.path)
      .toList();
}