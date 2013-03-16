library db_acccess_test;

import 'package:unittest/unittest.dart';
import 'package:higgins_server/higgins_server.dart';

BuildDao buildDao ;

main(){
  group('Configuration file', () {
    setUp(() => _setUp());
    tearDown(() => _tearDown());
    test('should find all', () => should_find_all());
  });
}

_setUp(){
  initMongo("mongodb://localhost");
  buildDao = new BuildDao();
  // TODO insérer des données
}

_tearDown(){
 // closeMongo();
}


should_find_all(){
  // TODO test async
  //buildDao.all()
}
