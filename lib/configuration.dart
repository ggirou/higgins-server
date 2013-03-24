part of higgins_server;

Configuration configuration;

/**
 * Configuration for Higgins server.
 */
abstract class Configuration {
  /** Listen for HTTP requests on the specified [host]. */
  String get host => "127.0.0.1";

  /** Listen for HTTP requests on the specified [port].
   * If a [port] of 0 is specified the server will choose an ephemeral port. */
  int get port => 0;

  /** Base path for the default static file handler. */
  String get basePath => "";

  /** The MongoDb uri. */
  String get mongoDbUri => "";

  /** The Path to the git executable binary */
  String get gitExecutablePath => "git";
  
  Configuration();

  factory Configuration.fromFile(String json) {
    return new ConfigurationFile.parse(json);
  }
}

class ConfigurationFile extends Configuration {
  String host = "127.0.0.1";
  int port = 0;
  String basePath = "";
  String mongoDbUri = "";
  String gitExecutablePath = "";

  ConfigurationFile.parse(String json, {Map<String, String> environment}) {
    if(!?environment) {
      environment = Platform.environment;
    }
    Map<String, Object> values = JSON.parse(json, _reviver(environment));
    if(values.containsKey("server")) {
      Map server = values["server"];
      host = server.containsKey("host") ?  server["host"] : host;
      port = server.containsKey("port") ?
          server["port"] is String ? int.parse(server["port"]) : server["port"]
          : port;
      basePath = server.containsKey("basePath") ?  server["basePath"] : basePath;
    }
    if(values.containsKey("mongoDb")) {
      Map mongoDb = values["mongoDb"];
      mongoDbUri = mongoDb.containsKey("uri") ?  mongoDb["uri"] : mongoDbUri;
    }
    if(values.containsKey("bin")) {
      Map bin = values["bin"];
      gitExecutablePath = bin.containsKey("gitExecutablePath") ?  bin["gitExecutablePath"] : gitExecutablePath;
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
