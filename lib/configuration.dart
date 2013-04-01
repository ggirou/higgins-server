part of higgins_server;

Configuration configuration;

/**
 * Configuration for Higgins server.
 */
class Configuration {
  /** Listen for HTTP requests on the specified [host]. */
  String get host => "127.0.0.1";

  /** Listen for HTTP requests on the specified [port].
   * If a [port] of 0 is specified the server will choose an ephemeral port. */
  int get port => 0;

  /** Base path for the default static file handler. */
  String get basePath => "";
  
  /** Build directory. */
  String get buildDir => "/tmp/";

  /** The MongoDb uri. */
  String get mongoDbUri => "";

  /** The Path to the git executable binary */
  String get gitExecutablePath => "git";
  
  const Configuration();
  
  factory Configuration.fromFile(String json) {
    return new ConfigurationFile.parse(json);
  }
}

class BaseConfiguration extends Configuration {
  String host;
  int port;
  String basePath;
  String buildDir;
  String mongoDbUri;
  String gitExecutablePath;
  
  BaseConfiguration([Configuration configuration = const Configuration()]) : host = configuration.host,
      port = configuration.port,
      basePath = configuration.basePath,
      buildDir = configuration.buildDir,
      mongoDbUri = configuration.mongoDbUri,
      gitExecutablePath = configuration.gitExecutablePath;
}

class ConfigurationFile extends BaseConfiguration {
  ConfigurationFile.parse(String json, {Map<String, String> environment}) {
    if(!?environment) {
      environment = Platform.environment;
    }
    Map<String, Object> values = JSON.parse(json, _reviver(environment));
    if(values.containsKey("server")) {
      Map server = values["server"];
      this.host = server.containsKey("host") ?  server["host"] : this.host;
      this.port = server.containsKey("port") ?
          server["port"] is String ? int.parse(server["port"]) : server["port"]
          : this.port;
      this.basePath = server.containsKey("basePath") ?  server["basePath"] : this.basePath;
    }
    if(values.containsKey("build")) {
      Map build = values["build"];
      this.buildDir = build.containsKey("buildDir") ?  build["buildDir"] : this.buildDir;
    }
    if(values.containsKey("mongoDb")) {
      Map mongoDb = values["mongoDb"];
      this.mongoDbUri = mongoDb.containsKey("uri") ?  mongoDb["uri"] : this.mongoDbUri;
    }
    if(values.containsKey("bin")) {
      Map bin = values["bin"];
      this.gitExecutablePath = bin.containsKey("gitExecutablePath") ?  bin["gitExecutablePath"] : this.gitExecutablePath;
    }
  }

  _reviver(Map<String, String> environment) => (key, value) {
      if(value is String && value.contains(r"$")) {
        environment.forEach((k, v) => value = value.replaceAll("\$$k", v));
        return value;
      } else {
        return value;
      }
    };
}
