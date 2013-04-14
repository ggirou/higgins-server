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
    test('Just connect', () {
      _setUp()
        .then((expectAsync1((bool success)  => expect(success, isTrue) )))
        .then((_) => _tearDown());
    });
    
    test('Job : Should find all',
                    () => _wrapFutureMethodTest(
                        () {},
                        () => jobQuery.all(),
                        (List result) => expect(result.length, equals(3)) 
                    ));
    
    test('Job : Should find a by name',
                    () => _wrapFutureMethodTest(() {},
                        () => jobQuery.findByJob("higgins-web"),
                        (List result) => expect(result.length, equals(1)) 
                    ));
    
    test('Job : Should find nothing when not exists', 
                    () => _wrapFutureMethodTest(               
                        () {},
                        () => jobQuery.findByJob("nonExist"),
                        (List result) => expect(result, isEmpty)
                    )); 
    
    test('BuildReport : Should find by id',
                    () {
                      var report = new JobBuildReport.fromData("Youpi");
                      _wrapFutureMethodTest(
                          () => report.save() ,
                          () => jobBuildReportQuery.findById(report.id),
                          (JobBuildReport result) => expect(result, equals(report)));
                     });

    test('BuildReport : Should not find and return null when incorrect id', 
                    () {
                      var report = new JobBuildReport.fromData("Youpi");
                      _wrapFutureMethodTest(
                          () => report.save() ,
                          () => jobBuildReportQuery.findById(new ObjectId()),
                          (JobBuildReport result) => expect(result, isNull));
                      });
    
    test('BuildReport : Save with specific Id',
         () {
           ObjectId reportId = JobBuildReport.generateId();
           var report = new JobBuildReport.fromData("Youpi");
           _wrapFutureMethodTest(
            () => report.saveWithId(reportId) ,
            () => jobBuildReportQuery.findById(reportId),
            (JobBuildReport result) {
              expect(result, isNotNull);
              expect(result, equals(report));
            });
     });
    
  });
}

_wrapFutureMethodTest(initMethod, testMethod, Function assertions){
  _setUp()
  .then((_) => initMethod())
  .then((_) => testMethod())
  .then((expectAsync1((result) => assertions(result))))
  .then((_) => _tearDown());  
}

Future<bool> _setUp(){
  Completer completer = new Completer();
  initMongo(MONGO_URL, dropCollectionsOnStartup: true).then((bool success) {
    jobQuery = new JobQuery();
    jobBuildReportQuery = new JobBuildReportQuery();
    _injectData();
    return  completer.complete(success);
  });
  return completer.future;
}

_injectData(){
  new Job.withName("higgins-web").save();
  new Job.withName("higgins-server").save();
  new Job.withName("higgins-heroku").save();
}

_tearDown(){
  closeMongo(); 
}
