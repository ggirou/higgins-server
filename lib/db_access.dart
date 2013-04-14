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
  objectory.registerClass(Job.OBJECT_NAME, () => new Job()); 
  objectory.registerClass(JobBuildReport.OBJECT_NAME, () => new JobBuildReport());
}

/**
 * Represent a Job
 * 
 * {
 *  "_id": {
 *      "$oid": "507e6b75e4b0b2834be2882e"
 *  },
 *  "name": "Dartlab",
 *  "repository": {
 *      "url": "git://github/dtc/ouille",
 *      "branche": "master"
 *  },
 *  "configuration": {
 *      "buildsHistorySize": 5
 *  },
 *  "builds": [
 *      {
 *          "number": 3,
 *          "status": "stable",
 *          "start": "2013-02-17T08:22:27.027Z",
 *          "end": "2013-02-17T08:23:27.027Z"
 *      },
 *      {
 *          "number": 2,
 *          "status": "failed",
 *          "start": "2013-02-17T08:20:01.027Z",
 *          "end": "2013-02-17T08:20:03.027Z"
 *      },
 *      {
 *          "number": 1,
 *          "status": "unstable",
 *          "start": "2013-02-17T07:20:01.027Z",
 *          "end": "2013-02-17T07:20:31.027Z"
 *      }
 *    ]
 *  }
 */
class Job extends PersistentObject {

  static final String OBJECT_NAME = "Job";
  static final String NAME_PARAM = "name";
  static final String REPOSITORY_PARAM = "repository";
  static final String CONFIGURATION__PARAM = "configuration";
  static final String BUILD_PARAM = "builds";
  static final String BUILD_ELEMENT_PARAM = "build";
  
  Job();
  
  Job.withName(String name){ // "this" sugar is failing
    this.name = name;
  }

  String get name => getProperty(NAME_PARAM);
  set name(String value) => setProperty(NAME_PARAM, value);
  
  String get repository => getProperty(REPOSITORY_PARAM);
  set repository(String value) => setProperty(REPOSITORY_PARAM, value);
  
  String get configuration => getProperty(CONFIGURATION__PARAM);
  set configuration(String value) => setProperty(CONFIGURATION__PARAM, value);
  
  List<JobBuild> get comments => new PersistentList<JobBuild>(this, BUILD_ELEMENT_PARAM, BUILD_PARAM);
  
}

class JobRepository extends EmbeddedPersistentObject {

  static final String OBJECT_NAME = "JobRepository";
  static final String URL_PARAM = "url";
  static final String BRANCH_PARAM = "branch";
  
  String get url => getProperty(URL_PARAM);
  set url(String value) => setProperty(URL_PARAM, value);
  
  String get branch => getProperty(BRANCH_PARAM);
  set branch(String value) => setProperty(BRANCH_PARAM, value);
  
}

class JobConfiguration extends EmbeddedPersistentObject {

  static final String OBJECT_NAME = "JobConfiguration";
  static final String BUILD_HISTORY_SIZE_PARAM = "buildsHistorySize";
  
  int get url => getProperty(BUILD_HISTORY_SIZE_PARAM);
  set url(int value) => setProperty(BUILD_HISTORY_SIZE_PARAM, value);
  
}

// TODO use a "enum" for status ?
class JobBuild extends EmbeddedPersistentObject {
  
  static final String OBJECT_NAME = "JobBuild";
  static final String NUMBER_PARAM = "number";
  static final String STATUS_PARAM = "status";
  static final String START_PARAM = "start";
  static final String END_PARAM = "end";
  
  JobBuild();
  
  int get number => getProperty(NUMBER_PARAM);
  set number(int value) => setProperty(NUMBER_PARAM, value);
  
  String get status => getProperty(STATUS_PARAM);
  set status(String value) => setProperty(STATUS_PARAM, value);
  
  DateTime get start => getProperty(START_PARAM);
  set start(DateTime value) => setProperty(START_PARAM, value);
  
  DateTime get end => getProperty(STATUS_PARAM);
  set end(DateTime value) => setProperty(END_PARAM, value);  
  
}

/**
 * Report represent a build log report.
 */
class JobBuildReport extends PersistentObject {
  
  static final String OBJECT_NAME = "BuildReport";
  static final String DATA_PARAM = "data";
  
  JobBuildReport();
  
  JobBuildReport.fromData(String data){// Sugar not working....
    this.data = data;
  }
  
  String get data => getProperty(DATA_PARAM);
  set data(String value) => setProperty(DATA_PARAM, value); 
  
}


/**
 * Queries for Job.
 */
class JobQuery {
  
  /**
   * Find all build.
   */
  Future<List<PersistentObject>> all() => objectory.find(_where);
  
  /**
   * Find build by jobName
   */
  Future<List<PersistentObject>> findByJob(String jobName) => objectory.find(_where.eq(Job.NAME_PARAM, jobName));
  
  ObjectoryQueryBuilder get _where => new ObjectoryQueryBuilder(Job.OBJECT_NAME);
  
}

/**
 * Queries for JobBuildReport
 */
class JobBuildReportQuery {
  
  Future<JobBuildReport> findById(ObjectId id) => objectory.findOne(_where.id(id));
  
  ObjectoryQueryBuilder get _where => new ObjectoryQueryBuilder(JobBuildReport.OBJECT_NAME);
  
}