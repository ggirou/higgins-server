library db_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/matcher.dart' as m;
import 'package:higgins_server/higgins_server.dart';
import 'package:mongo_dart/mongo_dart.dart';

const MONGO_URL = "mongodb://localhost";

JobQuery jobQuery;
JobBuildReportQuery jobBuildReportQuery;

main(){
  group('Mongo test', () {
    setUp(() => _setUp());
    tearDown(() => _tearDown());
    
    test('Job : Should find all',
      () => jobQuery.all().then((List result) => expect(result.length, equals(3)))
    );
    
    test('Job : Should find a by name',
      () => jobQuery.findByJob("higgins-web").then((Job result) => expect(result, isNotNull))
    );    
    
    test('Job : Should find nothing when not exists', 
      () => jobQuery.findByJob("nonExist").then((Job result) => expect(result, isNull))
    );  
    
    test('BuildReport : Should find by id',
      () {
        var report = new JobBuildReport.fromData("Youpi");
        report.save().then((_) => jobBuildReportQuery.findById(report.id))
                     .then((JobBuildReport result) => expect(result, equals(report)));
      }
    );    
  
    test('BuildReport : Should not find and return null when incorrect id', 
      () {
        var report = new JobBuildReport.fromData("Youpi");
        report.save().then((_) => jobBuildReportQuery.findById(new ObjectId()))
                     .then((JobBuildReport result) => expect(result, isNull));
      }
    );
    
    test('BuildReport : Save with specific Id',
      () {
        ObjectId reportId = JobBuildReport.generateId();
        var report = new JobBuildReport.fromData("Youpi");
        report.saveWithId(reportId).then((_) => jobBuildReportQuery.findById(reportId))
                                   .then((JobBuildReport result) {
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
    jobBuildReportQuery = new JobBuildReportQuery();
    _injectData().then((_) => completer.complete(success));
  });
  return completer.future;
}

Future _injectData() =>
  new Job.withName("higgins-web").save()
    .then((_) => new Job.withName("higgins-server").save())
    .then((_) => new Job.withName("higgins-heroku").save());

_tearDown(){
  closeMongo(); 
}
