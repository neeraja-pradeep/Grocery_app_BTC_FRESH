import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/app.dart';
import 'package:grocery_app/app/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  await AppBootstrap.run(() async => const ProviderScope(child: App()));
}
