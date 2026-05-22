import 'dart:convert';

import 'package:http/http.dart' as http;

class GraphQLService {
  static const String endpoint =
      'https://api-eoj2gtdea-faaezs-projects-373a7c11.vercel.app/graphql';

  Future<Map<String, dynamic>> query(
    String query, {
    Map<String, dynamic>? variables,
  }) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        if (variables != null) 'variables': variables,
      }),
    );

    final body = response.body.trimLeft();
    if (body.startsWith('<')) {
      throw Exception('Backend returned HTML instead of JSON. Check the GraphQL endpoint URL.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected GraphQL response format');
    }

    final errors = decoded['errors'];
    final data = decoded['data'];
    if (response.statusCode != 200 || errors != null || data == null) {
      throw Exception(errors ?? 'GraphQL request failed (${response.statusCode})');
    }

    return decoded;
  }

  Future<List<Map<String, dynamic>>> fetchNodes() async {
    final decoded = await query('''
      query {
        allNodes {
          nodeId
          nodeType
          name
          ipAddress
          status
          allProperties
        }
      }
    ''');

    final data = decoded['data'] as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(data?['allNodes'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> fetchSwitches() async {
    final decoded = await query('''
      query {
        allSwitches {
          name
        }
      }
    ''');

    final data = decoded['data'] as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(data?['allSwitches'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> fetchServers() async {
    final decoded = await query('''
      query {
        allServers {
          name
        }
      }
    ''');

    final data = decoded['data'] as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(data?['allServers'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> fetchIndirectRisks() async {
    final decoded = await query('''
      query {
        indirectRisks {
          source
          rel1Type
          mediator
          rel2Type
          target
          riskType
        }
      }
    ''');

    final data = decoded['data'] as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(data?['indirectRisks'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> fetchDevicesBySwitch(String switchName) async {
    final decoded = await query(
      '''
      query DevicesBySwitch(\$switchName: String!) {
        devicesBySwitch(switchName: \$switchName) {
          name
          ipAddress
          macAddress
        }
      }
    ''',
      variables: {'switchName': switchName},
    );

    final data = decoded['data'] as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(data?['devicesBySwitch'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> fetchAllRelationships() async {
    final decoded = await query('''
      query {
        allRelationships {
          sourceName
          sourceType
          relType
          targetName
          targetType
        }
      }
    ''');

    final data = decoded['data'] as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(data?['allRelationships'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> fetchLoadBalancers() async {
    final decoded = await query('''
      query {
        allLoadBalancers {
          name
        }
      }
    ''');

    final data = decoded['data'] as Map<String, dynamic>?;
    return List<Map<String, dynamic>>.from(data?['allLoadBalancers'] ?? const []);
  }
}