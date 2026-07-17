import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/frequently_bought_item.dart';
import '../../infrastructure/data_sources/remote/frequently_bought_data_source.dart';

/// Fetches the "Frequently Bought" list once per cart visit. Auto-disposes
/// when the cart screen unmounts so we don't hold a stale list across sessions.
final frequentlyBoughtProvider =
    FutureProvider.autoDispose<List<FrequentlyBoughtItem>>((ref) async {
      final remote = ref.watch(frequentlyBoughtRemoteDataSourceProvider);
      final response = await remote.fetch();
      return response.results.map((dto) => dto.toEntity()).toList(
        growable: false,
      );
    });
