// Create a new file: lib/app/services/pincode_service.dart
import 'package:dio/dio.dart';

class PincodeService {
  static final Dio _dio = Dio();

  static Future<Map<String, String>?> getLocationByPincode(String pincode) async {
    try {
      // Using India Post API (free and reliable)
      final response = await _dio.get(
        'https://api.postalpincode.in/pincode/$pincode',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final List data = response.data;
        if (data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffices = data[0]['PostOffice'] as List?;
          if (postOffices != null && postOffices.isNotEmpty) {
            final postOffice = postOffices[0];
            return {
              'city': postOffice['District'] ?? '',
              'state': postOffice['State'] ?? '',
            };
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching location for pincode $pincode: $e');
      return null;
    }
  }
}
