import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/providers/auth_provider.dart';
import '../../features/auth/application/states/auth_state.dart';

class AuthGuard {
  final Ref ref;

  AuthGuard(this.ref);

  bool get isAuthenticated {
    final state = ref.read(authProvider);
    return state is Authenticated;
  }

  String? protect({String redirectTo = '/login'}) {
    return isAuthenticated ? null : redirectTo;
  }
}
