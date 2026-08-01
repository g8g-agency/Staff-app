// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/network/realtime_sync_manager.dart';
import '../core/runtime/runtime_lifecycle.dart';
import '../features/alerts/presentation/widgets/non_blocking_alert_overlay.dart';
import '../core/services/session_service.dart';
import '../features/auth/presentation/state/auth_notifier.dart';
import '../features/auth/presentation/state/auth_state.dart';

class OrderlyyApp extends ConsumerStatefulWidget {
  const OrderlyyApp({super.key});

  @override
  ConsumerState<OrderlyyApp> createState() => _OrderlyyAppState();
}

class _OrderlyyAppState extends ConsumerState<OrderlyyApp> with WidgetsBindingObserver {
  late SessionService _sessionService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sessionService = SessionService(
      onTimeout: _handleSessionTimeout,
    );
  }

  void _handleSessionTimeout() {
    if (mounted) {
      debugPrint('[Session] Inactivity timeout reached. Locking session...');
      ref.read(authNotifierProvider.notifier).lockSession();
      ref.read(routerProvider).go('/lock');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionService.recordActivity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state to start/stop session monitoring
    ref.listen(authNotifierProvider, (previous, next) {
      final wasActive = previous?.isShiftStarted == true && previous?.isLocked == false;
      final isActive = next.isShiftStarted && !next.isLocked;
      
      if (isActive && !wasActive) {
        _sessionService.startMonitoring();
      } else if (!isActive && wasActive) {
        _sessionService.stopMonitoring();
      }
    });

    // Initialize Realtime Sync Manager to start receiving updates from admin app
    ref.read(realtimeSyncManagerProvider);

    // Initialize Runtime Lifecycle Manager to manage runtime sessions
    ref.read(runtimeLifecycleManagerProvider);

    final router = ref.watch(routerProvider);
    const themeMode = ThemeMode.light;

    return GestureDetector(
      onTap: () => _sessionService.recordActivity(),
      onPanDown: (_) => _sessionService.recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: MaterialApp.router(
        title: 'Orderlyy Restaurant Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();

          // Get the actual screen size
          final mediaQuery = MediaQuery.of(context);
          final screenSize = mediaQuery.size;

          // Set preferred orientations for mobile devices
          if (screenSize.width < 600) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          } else {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          }

          // Create responsive MediaQuery that adapts to any screen size
          return MediaQuery(
            data: mediaQuery.copyWith(
              // Ensure text scaling doesn't break the layout
              textScaler: TextScaler.linear(
                mediaQuery.textScaler.scale(1).clamp(0.8, 1.2),
              ),
            ),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                // Respect device safe areas (notches, home indicators, etc.)
                child: NonBlockingAlertOverlay(child: child),
              ),
            ),
          );
        },
        routerConfig: router,
      ),
    );
  }
}
