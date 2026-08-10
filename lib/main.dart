import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage/local_cache_service.dart';
import 'core/storage/sync_queue_service.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // Storage must be ready before any provider that reads/writes it
  // constructs (AuthController checks SecureStorageService synchronously
  // via a Future at startup; Tickets/Assets/KB controllers read the offline
  // cache). flutter_secure_storage needs no init call, but Hive does.
  await LocalCacheService.init();
  await SyncQueueService.init();

  runApp(const ProviderScope(child: ItsmApp()));
}

class ItsmApp extends ConsumerWidget {
  const ItsmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ITSM Framework',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Ensure consistent text scaling — clamp large system text scaling.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(
              mq.textScaler.scale(1).clamp(0.9, 1.15),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
