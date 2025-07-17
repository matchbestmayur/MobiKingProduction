import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/Home_model.dart';

class HomeService {
  Future<HomeLayoutModel?> getHomeLayout() async {
    final url = Uri.parse('https://mobiking-e-commerce-backend-prod.vercel.app/api/v1/home/');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print("✅ Raw Response Body:");
        print(jsonEncode(jsonData)); // Full JSON in compact form

        if (jsonData is Map<String, dynamic>) {
          final data = jsonData['data'];
          if (data is Map<String, dynamic>) {
            print("🔍 HomeLayout `data` content:");
            data.forEach((key, value) {
              print("➡ $key: ${value.runtimeType}");
              if (value is List || value is Map) {
                print(jsonEncode(value));
              } else {
                print(value);
              }
            });

            // Finally parse into your model
            final homeLayout = HomeLayoutModel.fromJson(data);
            return homeLayout;
          } else {
            print("❌ 'data' is not a Map<String, dynamic>");
            return null;
          }
        } else {
          print("❌ Unexpected JSON structure. Expected Map<String, dynamic>.");
          return null;
        }
      } else {
        print("❌ Failed to load home layout. Status code: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception during home layout fetch: $e");
      return null;
    }
  }
}
