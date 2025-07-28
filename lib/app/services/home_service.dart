import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../data/Home_model.dart';
import '../data/group_model.dart';

class HomeService {
  static const String _baseUrl = 'https://mobiking-e-commerce-backend-prod.vercel.app/api/v1';

  void _log(String message) {
    print('[HomeService] $message');
  }

  /// Get home layout with comprehensive error handling
  Future<HomeLayoutModel?> getHomeLayout() async {
    try {
      final url = Uri.parse('$_baseUrl/home/');
      _log('Fetching home layout from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while fetching home layout');
          return http.Response('Request timeout', 408);
        },
      );

      _log('Home layout response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          _log('✅ Successfully decoded JSON response');

          if (jsonData == null) {
            _log('❌ Response body is null');
            return null;
          }

          if (jsonData is Map<String, dynamic>) {
            final dynamic dataField = jsonData['data'];

            if (dataField == null) {
              _log('❌ No data field found in response');
              return null;
            }

            if (dataField is Map<String, dynamic>) {
              _log('🔍 HomeLayout data content validation passed');

              // Log data structure for debugging
              dataField.forEach((key, value) {
                try {
                  if (value is List) {
                    _log('➡ $key: List with ${value.length} items (${value.runtimeType})');
                  } else if (value is Map) {
                    _log('➡ $key: Map with ${value.length} keys (${value.runtimeType})');
                  } else {
                    _log('➡ $key: ${value.runtimeType} - ${value.toString().length > 100 ? '${value.toString().substring(0, 100)}...' : value}');
                  }
                } catch (e) {
                  _log('➡ $key: Error logging value - $e');
                }
              });

              try {
                final homeLayout = HomeLayoutModel.fromJson(dataField);
                _log('✅ Successfully parsed HomeLayoutModel');

                // Show success message for successful home layout load
               /* Get.snackbar('Success', 'Home content loaded successfully!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.shade600,
                    colorText: Colors.white);
*/
                return homeLayout;
              } catch (modelError) {
                _log('❌ Error parsing HomeLayoutModel: $modelError');
                return null;
              }
            } else {
              _log('❌ Data field is not a Map<String, dynamic>: ${dataField.runtimeType}');
              return null;
            }
          } else {
            _log('❌ Unexpected JSON structure. Expected Map<String, dynamic>, got: ${jsonData.runtimeType}');
            return null;
          }
        } catch (jsonError) {
          _log('❌ JSON parsing error: $jsonError');
          if (response.body.isNotEmpty) {
            _log('Response body preview: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
          }
          return null;
        }
      } else {
        _log('❌ Failed to load home layout. Status: ${response.statusCode} - ${response.reasonPhrase}');
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            _log('Error details: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
          } catch (e) {
            _log('Response body: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
          }
        }
        return null;
      }
    } catch (e) {
      _log('❌ Exception during home layout fetch: $e');
      return null;
    }
  }

  /// Get groups by category with comprehensive error handling
  Future<List<GroupModel>> getGroupsByCategory(String categoryId) async {
    // Input validation
    if (categoryId.trim().isEmpty) {
      _log('Error: Category ID is required');
      return <GroupModel>[];
    }

    try {
      final url = Uri.parse('$_baseUrl/groups/category/${categoryId.trim()}');
      _log('Fetching groups for category: $categoryId from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('Request timeout while fetching groups by category');
          return http.Response('Request timeout', 408);
        },
      );

      _log('Groups by category response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          _log('✅ Successfully decoded JSON response for groups');

          if (jsonData == null) {
            _log('❌ Response body is null');
            return <GroupModel>[];
          }

          if (jsonData is Map<String, dynamic>) {
            final dynamic dataField = jsonData['data'];

            if (dataField == null) {
              _log('❌ No data field found in groups response');
              return <GroupModel>[];
            }

            if (dataField is List) {
              if (dataField.isEmpty) {
                _log('✅ Empty groups list received for category: $categoryId');
                return <GroupModel>[];
              }

              _log('🔍 Processing ${dataField.length} groups');

              // Individual item error handling
              final List<GroupModel> groups = [];
              for (int i = 0; i < dataField.length; i++) {
                try {
                  final item = dataField[i];
                  if (item is Map<String, dynamic>) {
                    final group = GroupModel.fromJson(item);
                    groups.add(group);
                  } else {
                    _log('❌ Invalid group data at index $i: ${item.runtimeType}');
                  }
                } catch (e) {
                  _log('❌ Error parsing group at index $i: $e');
                  // Continue with other groups instead of failing completely
                }
              }

              _log('✅ Successfully parsed ${groups.length} groups out of ${dataField.length} items');

              // Show success message for successful groups fetch
              if (groups.isNotEmpty) {
              /*  Get.snackbar('Success', '${groups.length} products loaded successfully!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.shade600,
                    colorText: Colors.white);*/
              }

              return groups;
            } else {
              _log('❌ Expected a list in data field, got: ${dataField.runtimeType}');
              return <GroupModel>[];
            }
          } else {
            _log('❌ Unexpected JSON structure. Expected Map<String, dynamic>, got: ${jsonData.runtimeType}');
            return <GroupModel>[];
          }
        } catch (jsonError) {
          _log('❌ JSON parsing error in getGroupsByCategory: $jsonError');
          if (response.body.isNotEmpty) {
            _log('Response body preview: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
          }
          return <GroupModel>[];
        }
      } else {
        _log('❌ Failed to fetch groups. Status: ${response.statusCode} - ${response.reasonPhrase}');
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            _log('Error details: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}');
          } catch (e) {
            _log('Response body: ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
          }
        }
        return <GroupModel>[];
      }
    } catch (e) {
      _log('❌ Exception during fetch groups by category: $e');
      return <GroupModel>[];
    }
  }

  // Health check method
  Future<bool> checkServiceHealth() async {
    try {
      _log('Performing health check...');
      final url = Uri.parse('$_baseUrl/home/');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );

      final isHealthy = response.statusCode == 200;
      _log('Service health check: ${isHealthy ? 'Healthy' : 'Unhealthy'} (Status: ${response.statusCode})');
      return isHealthy;
    } catch (e) {
      _log('Health check failed: $e');
      return false;
    }
  }

  // Get groups by multiple categories
  Future<Map<String, List<GroupModel>>> getGroupsByMultipleCategories(List<String> categoryIds) async {
    if (categoryIds.isEmpty) {
      _log('Error: No category IDs provided');
      return <String, List<GroupModel>>{};
    }

    _log('Fetching groups for ${categoryIds.length} categories');
    final Map<String, List<GroupModel>> result = {};

    for (final categoryId in categoryIds) {
      if (categoryId.trim().isNotEmpty) {
        try {
          final groups = await getGroupsByCategory(categoryId);
          result[categoryId] = groups;
          _log('✅ Fetched ${groups.length} groups for category: $categoryId');
        } catch (e) {
          _log('❌ Error fetching groups for category $categoryId: $e');
          result[categoryId] = <GroupModel>[];
        }
      }
    }

    _log('✅ Completed fetching groups for ${result.length} categories');

    // Show success message for multiple categories fetch
    int totalGroups = result.values.fold(0, (sum, list) => sum + list.length);
    if (totalGroups > 0) {
     /* Get.snackbar('Success', 'Loaded $totalGroups products across ${result.length} categories!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white);*/
    }

    return result;
  }

  // Get group by ID with error handling
  Future<GroupModel?> getGroupById(String groupId) async {
    if (groupId.trim().isEmpty) {
      _log('Error: Group ID is required');
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl/groups/${groupId.trim()}');
      _log('Fetching group by ID: $groupId');

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('Request timeout', 408),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData is Map<String, dynamic>) {
            final dataField = jsonData['data'] ?? jsonData;
            if (dataField is Map<String, dynamic>) {
              final group = GroupModel.fromJson(dataField);
              _log('✅ Successfully fetched group: ${group.id}');

        /*      // Show success message for successful group fetch
              Get.snackbar('Success', 'Product details loaded successfully!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade600,
                  colorText: Colors.white);*/

              return group;
            }
          }

          _log('❌ Invalid response format for group ID: $groupId');
          return null;
        } catch (jsonError) {
          _log('❌ JSON parsing error for group ID $groupId: $jsonError');
          return null;
        }
      } else {
        _log('❌ Failed to fetch group ID $groupId. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _log('❌ Exception fetching group ID $groupId: $e');
      return null;
    }
  }

  // Search groups with error handling
  Future<List<GroupModel>> searchGroups(String query) async {
    if (query.trim().isEmpty) {
      _log('Empty search query provided');
      return <GroupModel>[];
    }

    try {
      final url = Uri.parse('$_baseUrl/groups/search?q=${Uri.encodeComponent(query.trim())}');
      _log('Searching groups with query: ${query.trim()}');

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () => http.Response('Request timeout', 408),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);

          if (jsonData is Map<String, dynamic>) {
            final dataField = jsonData['data'];
            if (dataField is List) {
              final List<GroupModel> groups = [];
              for (int i = 0; i < dataField.length; i++) {
                try {
                  final item = dataField[i];
                  if (item is Map<String, dynamic>) {
                    final group = GroupModel.fromJson(item);
                    groups.add(group);
                  }
                } catch (e) {
                  _log('Error parsing search result at index $i: $e');
                }
              }

              _log('✅ Found ${groups.length} groups matching query: ${query.trim()}');

              // Show success message for successful search
              if (groups.isNotEmpty) {
              /*  Get.snackbar('Success', 'Found ${groups.length} products matching "${query.trim()}"!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.shade600,
                    colorText: Colors.white);*/
              }

              return groups;
            }
          }

          _log('❌ Invalid search response format');
          return <GroupModel>[];
        } catch (jsonError) {
          _log('❌ JSON parsing error in searchGroups: $jsonError');
          return <GroupModel>[];
        }
      } else {
        _log('❌ Group search failed. Status: ${response.statusCode}');
        return <GroupModel>[];
      }
    } catch (e) {
      _log('❌ Exception during group search: $e');
      return <GroupModel>[];
    }
  }
}
