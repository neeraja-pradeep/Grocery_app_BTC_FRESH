import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/data_sources/local/auth_local_ds.dart';
import '../../infrastructure/data_sources/remote/auth_api.dart';
import '../../infrastructure/repositories/auth_repository_impl.dart';

part 'auth_repository_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final api = ref.watch(authApiProvider); // Inject AuthApi
  final local = ref.watch(authLocalDsProvider); // Inject AuthLocalDs

  return AuthRepositoryImpl(local: local, remote: api);
}
