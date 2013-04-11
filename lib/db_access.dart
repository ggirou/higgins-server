part of higgins_server;

/**
 * Initialize and start Mongo connexion with objectory.
 */
Future<bool> initMongo(String url, {bool dropCollectionsOnStartup: false}){
  print("Start mongo with $url");
  objectory = new ObjectoryDirectConnectionImpl(url,_registerClasses, dropCollectionsOnStartup);
  return objectory.initDomainModel();
}

/**
 * Close Mongo connexion.
 */
closeMongo(){
  print("Close mongo");
  objectory.close();
}

/**
 * Register classes in objectory
 */
_registerClasses(){
  objectory.registerClass(Build.NAME, () => new Build()); 
  objectory.registerClass(BuildReport.NAME, () => new BuildReport());
}

// TODO complete objetc
class Build extends PersistentObject {
  
  static final String NAME = "Build";
  static final String BUILD_ID_PARAM = "buildId";
  static final String JOB_PARAM = "job";
  static final String STATUS_PARAM = "status";
  
  Build();
  
  Build.from(buildId, job, status){// Sugar not working....
    this.buildId = buildId;
    this.job = job;
    this.status = status;
  }
  
  int get buildId => getProperty(BUILD_ID_PARAM);
  set buildId(int value) => setProperty(BUILD_ID_PARAM, value);
  
  String get job => getProperty(JOB_PARAM);
  set job(String value) => setProperty(JOB_PARAM, value); 

  String get status => getProperty(STATUS_PARAM);
  set status(String value) => setProperty(STATUS_PARAM, value);
  
  String toString() => "[buildId=$buildId job=$job status=$status]";
  
}

/**
 * Report represent a build log report.
 */
class BuildReport extends PersistentObject {
  
  static final String NAME = "BuildReport";
  static final String DATA_PARAM = "data";
  
  BuildReport();
  
  BuildReport.fromData(String data){// Sugar not working....
    this.data = data;
  }
  
  String get data => getProperty(DATA_PARAM);
  set data(String value) => setProperty(DATA_PARAM, value); 
  
}


/**
 * Dao for Build.
 */
class BuildDao {
  
  /**
   * Find all build.
   */
  Future<List<PersistentObject>> all() => objectory.find(_where);
  
  /**
   * Find build by jobName
   */
  Future<List<PersistentObject>> findByJob(String jobName) => objectory.find(_where.eq(Build.JOB_PARAM, jobName));
  
  ObjectoryQueryBuilder get _where => new ObjectoryQueryBuilder(Build.NAME);
  
}

class BuildReportDao {
  
  Future<BuildReport> findById(ObjectId id) => objectory.findOne(_where.id(id));
  
  ObjectoryQueryBuilder get _where => new ObjectoryQueryBuilder(Build.NAME);
  
}