part of higgins_server;


initMongo(String url){
  objectory = new ObjectoryDirectConnectionImpl(url,_registerClasses, false);
  objectory.initDomainModel();   
}

_registerClasses(){
  objectory.registerClass(Build.NAME, () => new Build()); 
}

class Build extends PersistentObject {
  
  static final String NAME = "Build";
  static final String BUILD_ID_PARAM = "buildId";
  static final String JOB_PARAM = "job";
  //static final String DATE_PARAM = "date";
  static final String STATUS_PARAM = "status";
  
  Build();
  
  Build.from(this.buildId, this.job, this.status);
  
  int get buildId => getProperty(BUILD_ID_PARAM);
  set buildId(int value) => setProperty(BUILD_ID_PARAM, value);
  
  String get job => getProperty(JOB_PARAM);
  set job(String value) => setProperty(JOB_PARAM, value); 

  //String get date => getProperty(DATE_PARAM);
  //set date(String value) => setProperty(DATE_PARAM, value);
  
  String get status => getProperty(STATUS_PARAM);
  set status(String value) => setProperty(STATUS_PARAM, value);
  
  String toString() => "[buildId=$buildId job=$job status=$status]";
  
}


class BuildDao {
  
  BuildDao(){

  }
  
  Future<List<PersistentObject>> all(){
    return objectory.find(_where);
  }
  
  Future<List<PersistentObject>> findByJob(String jobName){
    return objectory.find(_where.eq(Build.JOB_PARAM, jobName));
  }
  
  ObjectoryQueryBuilder get _where => new ObjectoryQueryBuilder(Build.NAME);
  
}