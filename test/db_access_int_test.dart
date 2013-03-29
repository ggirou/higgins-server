library db_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/matcher.dart' as m;
import 'package:higgins_server/higgins_server.dart';


const MONGO_URL = "mongodb://localhost";

BuildDao buildDao ;

main(){
  group('Mongo test', () {
    test('Just connect', () {
      _setUp()
        .then((expectAsync1((bool success) {
            expect(success, isTrue);
        })))
        .then((_) => _tearDown());
    });
    test('Should find all', () {
      _setUp()
        .then((_) => buildDao.all())
        .then((expectAsync1((List result) {
          expect(result.length, equals(3));
        })))
        .then((_) => _tearDown());
    });
    test('Should find jobs by jobname', () {
      _setUp()
        .then((_) => buildDao.findByJob("higgins-web"))
        .then((expectAsync1((List result) {
          expect(result.length, equals(2));
        })))
        .then((_) => _tearDown());
    });
    test('Should find nothing', () {
      _setUp()
        .then((_) => buildDao.findByJob("nonExist"))
        .then((expectAsync1((List result) {
          expect(result, isEmpty); 
        })))
        .then((_) => _tearDown());
    });   
  });
}

Future<bool> _setUp(){
  Completer completer = new Completer();
  initMongo(MONGO_URL, true).then((bool success) {
    buildDao = new BuildDao();
    _injectData();
    return  completer.complete(success);
  });
  return completer.future;
}

_injectData(){
   new Build.from(1, "higgins-web", "FAIL").save();
   new Build.from(2, "higgins-web", "SUCCESS").save();
   new Build.from(3, "higgins-server", "SUCCESS").save();
}

_tearDown(){
  closeMongo(); 
}
