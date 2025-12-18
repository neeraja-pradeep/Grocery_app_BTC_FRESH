import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/data_sources/admin_api.dart';
import '../../../core/utils/logger.dart';

/// State for admin phone number
class AdminPhoneState {
  final String? phoneNumber;
  final bool isLoading;
  final String? error;

  const AdminPhoneState({this.phoneNumber, this.isLoading = false, this.error});

  AdminPhoneState copyWith({
    String? phoneNumber,
    bool? isLoading,
    String? error,
  }) {
    return AdminPhoneState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing admin phone number with caching
class AdminPhoneNotifier extends StateNotifier<AdminPhoneState> {
  final AdminApi _adminApi;
  static const String _fallbackPhone = '+918089262564';

  AdminPhoneNotifier(this._adminApi) : super(const AdminPhoneState());

  /// Get admin phone number (cached or fetch from API)
  Future<String> getPhoneNumber() async {
    // Return cached value if available
    if (state.phoneNumber != null && state.phoneNumber!.isNotEmpty) {
      return state.phoneNumber!;
    }

    // Fetch from API
    state = state.copyWith(isLoading: true);

    try {
      final phone = await _adminApi.getAdminPhone();

      if (phone != null && phone.isNotEmpty) {
        state = state.copyWith(phoneNumber: phone, isLoading: false);
        Logger.info('Admin phone fetched successfully: $phone');
        return phone;
      } else {
        // Use fallback if API returns null/empty
        state = state.copyWith(phoneNumber: _fallbackPhone, isLoading: false);
        Logger.warning(
          'Admin phone not available from API, using fallback: $_fallbackPhone',
        );
        return _fallbackPhone;
      }
    } catch (e) {
      Logger.error('Failed to fetch admin phone, using fallback', error: e);
      state = state.copyWith(
        phoneNumber: _fallbackPhone,
        isLoading: false,
        error: e.toString(),
      );
      return _fallbackPhone;
    }
  }

  /// Clear cached phone number (forces refetch on next call)
  void clearCache() {
    state = const AdminPhoneState();
  }
}

/// Provider for admin phone number
final adminPhoneProvider =
    StateNotifierProvider<AdminPhoneNotifier, AdminPhoneState>((ref) {
      final adminApi = ref.watch(adminApiProvider);
      return AdminPhoneNotifier(adminApi);
    });
