library configuration_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/matcher.dart' as m;

import 'package:higgins_server/higgins_server.dart';

main() {
  group('Configuration file', () {
    test('parses an empty file', () {
      // GIVEN
      var json = '{}';

      // WHEN
      var output = new ConfigurationFile.parse(json);

      // THEN
      expect(output.host, m.equals("127.0.0.1"));
      expect(output.port, m.equals(0));
      expect(output.basePath, m.equals(""));
      expect(output.buildDir, m.equals("/tmp"));
      expect(output.mongoDbUri, m.equals(""));
      expect(output.gitExecutablePath, m.equals("git"));
      expect(output.pubExecutablePath, m.equals("pub"));
    });

    test('parses a file with empty categories', () {
      // GIVEN
      var json = '''{
        "server" : { },
        "mongoDb" : { },
        "build" : { },
        "bin" : { }
      }''';

      // WHEN
      var output = new ConfigurationFile.parse(json);

      // THEN
      expect(output.host, m.equals("127.0.0.1"));
      expect(output.port, m.equals(0));
      expect(output.basePath, m.equals(""));
      expect(output.buildDir, m.equals("/tmp"));
      expect(output.mongoDbUri, m.equals(""));
      expect(output.gitExecutablePath, m.equals("git"));
      expect(output.pubExecutablePath, m.equals("pub"));
    });

    test('parses a simple file', () {
      // GIVEN
      var json = '''{
        "#":"Comments",
        "server" : {
          "host" : "127.0.0.1",
          "#":"Other comments",
          "port" : 666,
          "basePath" : "../web/web"
        },
        "mongoDb" : {
          "uri" : "mongodb://username:password@host:port/database"
        },
        "build" : {
          "buildDir" : "/tmp/higgins/build"
        },
        "bin" : {
          "git" : "/usr/bin/git",
          "pub" : "/usr/bin/pub"
        }
      }''';

      // WHEN
      var output = new ConfigurationFile.parse(json);

      // THEN
      expect(output.host, m.equals("127.0.0.1"));
      expect(output.port, m.equals(666));
      expect(output.basePath, m.equals("../web/web"));
      expect(output.buildDir, m.equals("/tmp/higgins/build"));
      expect(output.mongoDbUri, m.equals("mongodb://username:password@host:port/database"));
      expect(output.gitExecutablePath, m.equals("/usr/bin/git"));
      expect(output.pubExecutablePath, m.equals("/usr/bin/pub"));
    });

    test('parses a file with environment variables', () {
      // GIVEN
      var json = r'''{
        "server" : {
          "host" : "$HOST",
          "port" : "$PORT",
          "basePath" : "$BASE_PATH"
        },
        "mongoDb" : {
          "uri" : "mongodb://$MONGODB_USERNAME:$MONGODB_PASSWORD@host:port/database"
        },
        "build" : {
          "buildDir" : "$TMPDIR"
        },
        "bin" : {
          "git" : "$GIT_EXECUTABLE_PATH",
          "pub" : "$DART_SDK/bin/pub"
        }
      }''';
      var environment = {
        "HOST": "192.168.0.1",
        "PORT": "42",
        "BASE_PATH": "xxx/yyy",
        "TMPDIR": "/tmp/dir",
        "MONGODB_USERNAME": "myusername",
        "MONGODB_PASSWORD": "mypassword",
        "GIT_EXECUTABLE_PATH": "/usr/bin/git",
        "DART_SDK": "/usr/local/dart-sdk",
      };

      // WHEN
      var output = new ConfigurationFile.parse(json, environment: environment);

      // THEN
      expect(output.host, m.equals("192.168.0.1"));
      expect(output.port, m.equals(42));
      expect(output.basePath, m.equals("xxx/yyy"));
      expect(output.buildDir, m.equals("/tmp/dir"));
      expect(output.mongoDbUri, m.equals("mongodb://myusername:mypassword@host:port/database"));
      expect(output.gitExecutablePath, m.equals("/usr/bin/git"));
      expect(output.pubExecutablePath, m.equals("/usr/local/dart-sdk/bin/pub"));
    });
  });
}

