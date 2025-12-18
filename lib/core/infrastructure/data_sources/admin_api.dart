import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import '../../network/endpoints.dart';

/// Data source for admin-related API calls
class AdminApi {
  final ApiClient _apiClient;

  AdminApi(this._apiClient);

  /// Fetch admin phone number from backend
  /// Returns the phone number string or null if not available
  Future<String?> getAdminPhone() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.adminPhone);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        // Assuming API returns: { "phone": "+918089262564" }
        return data['phone'] as String?;
      }

      return null;
    } on DioException catch (e) {
      // Return null on error - will use fallback number
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Error fetching admin phone: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for AdminApi
final adminApiProvider = Provider<AdminApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminApi(apiClient);
});
