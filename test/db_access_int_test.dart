library db_test;

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/matcher.dart' as m;
import 'package:higgins_server/higgins_server.dart';

const MONGO_URL = "mongodb://localhost";

BuildDao buildDao ;
BuildReportDao buildReportDao;

// FIXME bof bof
var reportId;
BuildReport report;

main(){
  group('Mongo test', () {
    test('Just connect', () {
      _setUp()
        .then((expectAsync1((bool success)  => expect(success, isTrue) )))
        .then((_) => _tearDown());
    });
    
    test('Build : Should find all', () => _wrapFutureMethodTest(() => buildDao.all(),
                            (List result) => expect(result.length, equals(3)) ));
    
    test('Build : Should find jobs by jobname', () => _wrapFutureMethodTest(() => buildDao.findByJob("higgins-web"),
                            (List result) => expect(result.length, equals(2)) ));
    
    test('Build : Should find nothing', () => _wrapFutureMethodTest(() => buildDao.findByJob("nonExist"),
                            (List result) => expect(result, isEmpty) )); 
    
    test('BuildReport : Should find by id', () => _wrapFutureMethodTest(() => buildReportDao.findById(report.id),
                            (BuildReport result) => expect(result, equals(report)) ));

    test('BuildReport : Should not find and return null when incorrect id', () => _wrapFutureMethodTest(() => buildReportDao.findById(BuildReport.generateId()),
                            (BuildReport result) => expect(result, isNull)));    
    
    test('BuildReport : Save with specific Id', () {
        expect(reportId, isNotNull);
        _wrapFutureMethodTest(() => buildReportDao.findById(reportId),
                                    (BuildReport result) => expect(result, isNotNull));
    });    
    
  });
}

_wrapFutureMethodTest(future, Function assertions){
  _setUp()
  .then((_) => future())
  .then((expectAsync1((result) => assertions(result))))
  .then((_) => _tearDown());  
}

Future<bool> _setUp(){
  Completer completer = new Completer();
  initMongo(MONGO_URL, dropCollectionsOnStartup: true).then((bool success) {
    buildDao = new BuildDao();
    buildReportDao = new BuildReportDao();
    _injectData();
    return  completer.complete(success);
  });
  return completer.future;
}

_injectData(){
   new Build.from(1, "higgins-web", "FAIL").save();
   new Build.from(2, "higgins-web", "SUCCESS").save();
   new Build.from(3, "higgins-server", "SUCCESS").save();
   report = new BuildReport.fromData("Youpi");
   report.save();
   reportId = BuildReport.generateId();
   new BuildReport.fromData("It build !").saveWithId(reportId);
}

_tearDown(){
  closeMongo(); 
}
