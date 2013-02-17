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
      expect(output.mongoDbUri, m.equals(""));
    });

    test('parses a file with empty categories', () {
      // GIVEN
      var json = '''{
        "server" : { },
        "mongoDb" : { }
      }''';
      
      // WHEN
      var output = new ConfigurationFile.parse(json);
      
      // THEN
      expect(output.host, m.equals("127.0.0.1"));
      expect(output.port, m.equals(0));
      expect(output.basePath, m.equals(""));
      expect(output.mongoDbUri, m.equals(""));
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
        }
      }''';
      
      // WHEN
      var output = new ConfigurationFile.parse(json);
      
      // THEN
      expect(output.host, m.equals("127.0.0.1"));
      expect(output.port, m.equals(666));
      expect(output.basePath, m.equals("../web/web"));
      expect(output.mongoDbUri, m.equals("mongodb://username:password@host:port/database"));
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
        }
      }''';
      var environment = {
        "HOST": "192.168.0.1",
        "PORT": "42",
        "BASE_PATH": "xxx/yyy",
        "MONGODB_USERNAME": "myusername",
        "MONGODB_PASSWORD": "mypassword",
      };
      
      // WHEN
      var output = new ConfigurationFile.parse(json, environment: environment);
      
      // THEN
      expect(output.host, m.equals("192.168.0.1"));
      expect(output.port, m.equals(42));
      expect(output.basePath, m.equals("xxx/yyy"));
      expect(output.mongoDbUri, m.equals("mongodb://myusername:mypassword@host:port/database"));
    });
  });
}

