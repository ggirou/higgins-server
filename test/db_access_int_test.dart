library db_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/matcher.dart' as m;
import 'package:higgins_server/higgins_server.dart';
import 'package:mongo_dart/mongo_dart.dart';

const MONGO_URL = "mongodb://localhost";
//const MONGO_URL = "mongodb://db_test:db_test@dbh62.mongolab.com:27627/higgins_test";// Use it if you don't have mongo

JobQuery jobQuery;
BuildOutputQuery buildOutputQuery;

main(){
  group('Mongo test', () {
    setUp(() => _setUp());
    tearDown(() => _tearDown());
    
    test('Job : Should find all',
      // When  
      () => jobQuery.all().then(
          // Then
          (List result) => expect(result.length, equals(3)))
    );
    
    test('Job : Should find a by name',
      // When  
      () => jobQuery.findByJob("higgins-web").then(
          // Then
          (Job result) => expect(result, isNotNull))
    );    

    test('Job : Should find nothing when not exists', 
      // When  
      () => jobQuery.findByJob("nonExist").then(
          // Then
          (Job result) => expect(result, isNull))
    );  
    
    test('BuildReport : Should find by id',
      () {
        // Given
        var report = new BuildOutput.fromData("Youpi");
        report.save().then(
            // When
            (_) => buildOutputQuery.findById(report.id))
                     .then(
                         // Then
                         (BuildOutput result) => expect(result, equals(report)));
      }
    );    
  
    test('BuildReport : Should not find and return null when incorrect id', 
      () {
        // Given
        var report = new BuildOutput.fromData("Youpi");
        // When
        report.save().then(
            // Then
            (_) => buildOutputQuery.findById(new ObjectId()))
                     .then((BuildOutput result) => expect(result, isNull));
      }
    );
    
    test('BuildReport : Save with specific Id',
      () {
        // Given
        ObjectId reportId = BuildOutput.generateId();
        var report = new BuildOutput.fromData("Youpi");
        report.saveWithId(reportId).then(
            // When
            (_) => buildOutputQuery.findById(reportId))
                                   .then(
                                       // Then
                                       (BuildOutput result) {
                                          expect(result, isNotNull);
                                          expect(result, equals(report));
                                       });
        }
      );    

  });
}

Future<bool> _setUp(){
  Completer completer = new Completer();
  initMongo(MONGO_URL, dropCollectionsOnStartup: true).then((bool success) {
    jobQuery = new JobQuery();
    buildOutputQuery = new BuildOutputQuery();
    _injectData().then((_) => completer.complete(success));
  });
  return completer.future;
}

Future _injectData() =>
  new Job.withName("higgins-web").save()
    .then((_) => new Job.withName("higgins-server").save())
    .then((_) => new Job.withName("higgins-heroku").save());

_tearDown() => closeMongo();

