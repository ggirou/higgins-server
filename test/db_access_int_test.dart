library db_acccess_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/matcher.dart' as m;
import 'package:higgins_server/higgins_server.dart' as db;

//BuildDao buildDao ;

main(){
  group('Configuration file', () {
    test('Only connect', (){
      db.initMongo("mongodb://localhost").then((bool success) {
        expect(success, m.isTrue);
        db.closeMongo(); 
      });
    });
  });
}