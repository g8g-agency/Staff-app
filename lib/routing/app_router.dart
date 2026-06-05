// lib/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/observers/routing_observer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../features/tables/presentation/screens/table_grid_screen.dart';
import '../features/tables/presentation/screens/table_detail_screen.dart';
import '../features/orders/presentation/screens/order_editor_screen.dart';
import '../features/billing/presentation/screens/billing_payment_screen.dart';
import '../features/kitchen/presentation/screens/kitchen_kds_screen.dart';
import '../features/auth/presentation/state/auth_notifier.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/device_registration_screen.dart';
import '../features/auth/presentation/screens/staff_login_screen.dart';
import '../features/auth/presentation/screens/shift_start_screen.dart';
import '../features/auth/presentation/screens/session_lock_screen.dart';
import '../core/storage/device_context_store.dart';
import '../features/dashboard/presentation/screens/operational_dashboard_screen.dart';
import '../features/orders/presentation/screens/active_orders_feed_screen.dart';
import '../features/orders/presentation/screens/order_details_screen.dart';
import '../features/orders/presentation/screens/item_level_kitchen_status_screen.dart';
import '../features/tables/presentation/screens/table_split_screen.dart';
import '../features/waiter_calls/presentation/screens/waiter_call_feed_screen.dart';
import '../features/waiter_calls/presentation/screens/waiter_call_details_screen.dart';
import '../features/notifications/presentation/screens/notification_center_screen.dart';
import '../features/kitchen/presentation/screens/ready_orders_feed_screen.dart';
import '../features/kitchen/presentation/screens/delayed_orders_feed_screen.dart';
import '../features/billing/presentation/screens/payment_pending_feed_screen.dart';
import '../features/billing/presentation/screens/receipt_preview_screen.dart';
import '../features/notifications/presentation/state/notifications_provider.dart';
import '../features/waiter_calls/presentation/state/waiter_calls_providers.dart';
// Volume II — Screen imports
import '../features/shift/presentation/screens/shift_dashboard_screen.dart';
import '../features/shift/presentation/screens/shift_close_screen.dart';
import '../features/staff/presentation/screens/staff_presence_screen.dart';
import '../features/realtime/presentation/screens/realtime_status_screen.dart';
import '../features/realtime/presentation/screens/pending_sync_screen.dart';
import '../features/realtime/presentation/screens/operational_recovery_screen.dart';
import '../features/profile/presentation/screens/developer_dashboard_screen.dart';
import '../features/profile/presentation/screens/staff_profile_screen.dart';
import '../features/profile/presentation/screens/profile_setup_screen.dart';
import '../features/profile/presentation/screens/developer_settings_screen.dart';
import '../features/manager/presentation/screens/floor_analytics_screen.dart';
import '../features/manager/presentation/screens/staff_performance_screen.dart';
import '../features/manager/presentation/screens/operational_alerts_screen.dart';
import '../features/realtime/presentation/state/realtime_providers.dart';
import '../features/realtime/domain/entities/realtime_state_model.dart';
import '../core/widgets/realtime_banner.dart';
import '../core/network/realtime_sync_manager.dart';
import '../features/orders/presentation/widgets/incoming_order_alert_overlay.dart';

// Derived provider: count of active (unresolved) waiter calls for badge display
final activeWaiterCallsCountProvider = Provider<int>((ref) {
  final calls = ref.watch(activeWaiterCallsProvider);
  return calls.length;
});

// RouterNotifier acts as a bridge between Riverpod and GoRouter.
// It listens to auth state changes and notifies GoRouter to trigger a redirect.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, next) => notifyListeners(),
    );
    _ref.listen<RealtimeStateModel>(
      realtimeStateProvider,
      (_, next) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    observers: [AppRoutingObserver()],
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final loc = state.uri.path;

      debugPrint(
        '[ROUTER] redirect evaluation: location=$loc, isLocked=${authState.isLocked}, isShiftStarted=${authState.isShiftStarted}, org=${authState.selectedOrg?.name}, branch=${authState.selectedBranch?.name}',
      );

      // Handle the default platform route
      if (loc == '/') {
        return '/splash';
      }

      // If we are on the splash screen, do NOT redirect. Let it perform its bootloader diagnostics.
      if (loc == '/splash') {
        return null;
      }

      // Check for critical realtime connection failure
      final realtimeState = ref.read(realtimeStateProvider);
      if (realtimeState.connectionState == RealtimeConnectionState.critical) {
        if (loc != '/realtime/recovery') {
          return '/realtime/recovery';
        }
        return null;
      }

      // If we recovered and are still on the recovery screen, go back to main screen
      if (loc == '/realtime/recovery') {
        return '/tables';
      }

      // If locked, staff must go to/stay on session lock screen
      if (authState.isLocked) {
        if (loc != '/lock') {
          return '/lock';
        }
        return null;
      }

      // Ensure locked screen is not bypassed when not locked
      if (loc == '/lock' && !authState.isLocked) {
        return '/tables';
      }

      // Main authentication routing state machine
      final deviceStore = ref.read(deviceContextStoreProvider);

      if (!deviceStore.hasContext) {
        if (loc != '/welcome' && loc != '/device-registration') {
          return '/welcome';
        }
        return null;
      }

      if (authState.loggedInStaff == null) {
        if (loc != '/login' && loc != '/device-registration') {
          return '/login';
        }
        return null;
      }

      if (!authState.isShiftStarted) {
        if (loc != '/shift-start' &&
            loc != '/login' &&
            loc != '/device-registration') {
          return '/shift-start';
        }
        return null;
      }

      // If logged in, shift started, operational, and not locked...

      // Enforce profile completion
      final staff = authState.loggedInStaff;
      if (staff != null && !staff.profileCompleted) {
        if (loc != '/profile-setup') {
          return '/profile-setup';
        }
        return null;
      }

      // If profile is completed, ensure they can't access profile-setup manually
      if (loc == '/profile-setup' && staff != null && staff.profileCompleted) {
        return '/tables';
      }

      // Block access to auth configuration screens
      final isAuthScreen =
          loc == '/device-registration' ||
          loc == '/login' ||
          loc == '/shift-start';

      if (isAuthScreen) {
        return '/tables';
      }

      // Allow access to the target route
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/device-registration',
        name: 'device-registration',
        builder: (context, state) => const DeviceRegistrationScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const StaffLoginScreen(),
      ),
      GoRoute(
        path: '/shift-start',
        name: 'shift-start',
        builder: (context, state) => const ShiftStartScreen(),
      ),
      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (context, state) => const SessionLockScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return NavigationShellLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/tables',
            name: 'tables',
            builder: (context, state) => const TableGridScreen(),
          ),
          GoRoute(
            path: '/orders-feed',
            name: 'orders-feed',
            builder: (context, state) => const ActiveOrdersFeedScreen(),
          ),
          GoRoute(
            path: '/kds',
            name: 'kds',
            builder: (context, state) => const KitchenKdsScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const OperationalDashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const StaffProfileScreen(),
          ),
          GoRoute(
            path: '/developer',
            name: 'developer',
            builder: (context, state) => const DeveloperDashboardScreen(),
          ),
          GoRoute(
            path: '/settings/developer',
            name: 'settings-developer',
            builder: (context, state) => const DeveloperSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tables/:id',
        name: 'table-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TableDetailScreen(tableId: id);
        },
      ),
      GoRoute(
        path: '/tables/:id/edit',
        name: 'order-editor',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderEditorScreen(tableId: id);
        },
      ),
      GoRoute(
        path: '/tables/:id/pay',
        name: 'billing-payment',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BillingPaymentScreen(tableId: id);
        },
      ),
      GoRoute(
        path: '/orders/:id/details',
        name: 'order-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailsScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/tables/:id/split',
        name: 'table-split',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TableSplitScreen(tableId: id);
        },
      ),
      GoRoute(
        path: '/kitchen/status',
        name: 'kitchen-status',
        builder: (context, state) => const ItemLevelKitchenStatusScreen(),
      ),
      GoRoute(
        path: '/waiter-calls',
        name: 'waiter-calls',
        builder: (context, state) => const WaiterCallFeedScreen(),
      ),
      GoRoute(
        path: '/waiter-calls/:id',
        name: 'waiter-call-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WaiterCallDetailsScreen(callId: id);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/kitchen/ready',
        name: 'kitchen-ready',
        builder: (context, state) => const ReadyOrdersFeedScreen(),
      ),
      GoRoute(
        path: '/kitchen/delayed',
        name: 'kitchen-delayed',
        builder: (context, state) => const DelayedOrdersFeedScreen(),
      ),
      GoRoute(
        path: '/billing/pending',
        name: 'billing-pending',
        builder: (context, state) => const PaymentPendingFeedScreen(),
      ),
      GoRoute(
        path: '/tables/:id/receipt-preview',
        name: 'receipt-preview',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReceiptPreviewScreen(tableId: id);
        },
      ),
      // ── Volume II Routes ──────────────────────────────────────────────
      GoRoute(
        path: '/shift/dashboard',
        name: 'shift-dashboard',
        builder: (context, state) => const ShiftDashboardScreen(),
      ),
      GoRoute(
        path: '/shift/close',
        name: 'shift-close',
        builder: (context, state) => const ShiftCloseScreen(),
      ),
      GoRoute(
        path: '/staff/presence',
        name: 'staff-presence',
        builder: (context, state) => const StaffPresenceScreen(),
      ),
      GoRoute(
        path: '/realtime/status',
        name: 'realtime-status',
        builder: (context, state) => const RealtimeStatusScreen(),
      ),
      GoRoute(
        path: '/realtime/sync-queue',
        name: 'sync-queue',
        builder: (context, state) => const PendingSyncScreen(),
      ),
      GoRoute(
        path: '/realtime/recovery',
        name: 'operational-recovery',
        builder: (context, state) => const OperationalRecoveryScreen(),
      ),
      GoRoute(
        path: '/diagnostics',
        name: 'runtime-diagnostics',
        builder: (context, state) => const DeveloperDashboardScreen(),
      ),
      GoRoute(
        path: '/manager/analytics',
        name: 'floor-analytics',
        builder: (context, state) => const FloorAnalyticsScreen(),
      ),
      GoRoute(
        path: '/manager/staff-performance',
        name: 'staff-performance',
        builder: (context, state) => const StaffPerformanceScreen(),
      ),
      GoRoute(
        path: '/manager/alerts',
        name: 'operational-alerts',
        builder: (context, state) => const OperationalAlertsScreen(),
      ),
    ],
  );
});

// NavigationShellLayout is a ConsumerWidget so it can watch live badge counts.
class NavigationShellLayout extends ConsumerWidget {
  final Widget child;

  const NavigationShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    // Live badge providers
    final unreadNotifCount = ref.watch(unreadNotificationsCountProvider);
    final activeCallCount = ref.watch(activeWaiterCallsCountProvider);
    final realtimeState = ref.watch(realtimeStateProvider);
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int selectedIndex = 0;
    if (location.startsWith('/orders-feed')) {
      selectedIndex = 1;
    } else if (location.startsWith('/dashboard')) {
      selectedIndex = 2;
    } else if (location.startsWith('/profile') ||
        location.startsWith('/developer') ||
        location.startsWith('/settings/developer') ||
        location.startsWith('/diagnostics')) {
      selectedIndex = 3;
    }

    RealtimeState mapState(RealtimeConnectionState s) {
      switch (s) {
        case RealtimeConnectionState.connected:
          return RealtimeState.connected;
        case RealtimeConnectionState.reconnecting:
          return RealtimeState.reconnecting;
        case RealtimeConnectionState.replaying:
          return RealtimeState.replaying;
        case RealtimeConnectionState.degraded:
          return RealtimeState.degraded;
        case RealtimeConnectionState.critical:
          return RealtimeState.critical;
      }
    }

    final isDevRoute =
        location.startsWith('/developer') ||
        location.startsWith('/settings/developer');
    final isProfileRoute = location.startsWith('/profile');
    final isDev = authState.loggedInStaff?.developerModeEnabled ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        final bodyContent = OrderAlertListener(
          child: Stack(
            children: [
              child,
              RealtimeBanner(
                state: mapState(realtimeState.connectionState),
                reconnectAttempt: realtimeState.reconnectAttempts,
                onRetry: () {
                  ref.read(realtimeSyncManagerProvider).connectLocal();
                },
              ),
            ],
          ),
        );

        final scaffold = Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _buildTopActionBar(
              context,
              unreadNotifCount,
              activeCallCount,
              authState.selectedBranch?.name ?? 'Main Kitchen',
              isDark,
              isDesktop,
            ),
          ),
          body: isDesktop
              ? Row(
                  children: [
                    _buildNavigationRail(
                      context,
                      selectedIndex,
                      isDevRoute,
                      isProfileRoute,
                      isDev,
                      activeCallCount,
                      isDark,
                    ),
                    VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                    Expanded(child: bodyContent),
                  ],
                )
              : bodyContent,
          bottomNavigationBar: isDesktop
              ? null
              : _buildBottomNavigationBar(
                  context,
                  selectedIndex,
                  isDevRoute,
                  isProfileRoute,
                  isDev,
                  activeCallCount,
                  isDark,
                ),
        );

        return scaffold;
      },
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    int selectedIndex,
    bool isDevRoute,
    bool isProfileRoute,
    bool isDev,
    int activeCallCount,
    bool isDark,
  ) {
    return Container(
      width: 80,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildNavItem(context, Icons.table_restaurant_rounded, 'Tables', selectedIndex == 0, isDark, () => context.go('/tables'), badgeCount: activeCallCount, isRail: true),
            _buildNavItem(context, Icons.receipt_long_rounded, 'Orders', selectedIndex == 1, isDark, () => context.go('/orders-feed'), isRail: true),
            _buildNavItem(context, Icons.dashboard_rounded, 'Dashboard', selectedIndex == 2, isDark, () => context.go('/dashboard'), isRail: true),
            if (isDev)
              _buildNavItem(context, Icons.terminal_rounded, 'Developer', isDevRoute, isDark, () => context.go('/developer'), isRail: true),
            const Spacer(),
            _buildNavItem(context, Icons.person_rounded, 'Profile', isProfileRoute, isDark, () => context.go('/profile'), isRail: true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    int selectedIndex,
    bool isDevRoute,
    bool isProfileRoute,
    bool isDev,
    int activeCallCount,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              Icons.table_restaurant_rounded,
              'Tables',
              selectedIndex == 0,
              isDark,
              () => context.go('/tables'),
              badgeCount: activeCallCount,
            ),
            _buildNavItem(
              context,
              Icons.receipt_long_rounded,
              'Orders',
              selectedIndex == 1,
              isDark,
              () => context.go('/orders-feed'),
            ),
            _buildNavItem(
              context,
              Icons.dashboard_rounded,
              'Dashboard',
              selectedIndex == 2,
              isDark,
              () => context.go('/dashboard'),
            ),
            if (isDev)
              _buildNavItem(
                context,
                Icons.terminal_rounded,
                'Developer',
                isDevRoute,
                isDark,
                () => context.go('/developer'),
              ),
            _buildNavItem(
              context,
              Icons.person_rounded,
              'Profile',
              isProfileRoute,
              isDark,
              () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap, {
    int badgeCount = 0,
    bool isRail = false,
  }) {
    const activeColor = Color(0xFFE31E24);
    final activeBg = activeColor.withValues(alpha: 0.1);
    final inactiveColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    Widget iconWidget = Icon(
      icon,
      color: isActive ? activeColor : inactiveColor,
      size: 24,
    );
    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text('$badgeCount'),
        backgroundColor: AppColors.error,
        child: iconWidget,
      );
    }

    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? activeBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: iconWidget,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? activeColor : inactiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    return isRail
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: item,
          )
        : Expanded(child: item);
  }

  Widget _buildTopActionBar(
    BuildContext context,
    int unreadNotifCount,
    int activeCallCount,
    String branchName,
    bool isDark,
    bool isDesktop,
  ) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Store Title
              Row(
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    color: isDark
                        ? const Color(0xFFffb4ab)
                        : const Color(0xFFE31E24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    branchName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFffb4ab)
                          : const Color(0xFFE31E24),
                    ),
                  ),
                ],
              ),
              // Action Icons
              Row(
                children: [
                  // More operational shortcuts via bottom sheet
                  ElevatedButton.icon(
                    icon: const Icon(Icons.grid_view_rounded, size: 20),
                    label: Text(
                      'Quick Access',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showQuickAccessSheet(context),
                  ),
                  const SizedBox(width: 12),
                  // Notification center with unread badge
                  IconButton(
                    icon: unreadNotifCount > 0
                        ? Badge(
                            label: Text('$unreadNotifCount'),
                            backgroundColor: AppColors.error,
                            child: const Icon(Icons.notifications_rounded),
                          )
                        : const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAccessSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      'Quick Access',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.support_agent_rounded,
                          label: 'Waiter Calls',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/waiter-calls');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.delivery_dining_rounded,
                          label: 'Kitchen Ready',
                          color: AppColors.success,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/kitchen/ready');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.timer_off_rounded,
                          label: 'Delayed Tickets',
                          color: AppColors.error,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/kitchen/delayed');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Pending Bills',
                          color: AppColors.warning,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/billing/pending');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.history_rounded,
                          label: 'Order History',
                          color: Colors.deepPurpleAccent,
                          onTap: () {
                            context.pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.developer_mode_rounded,
                          label: 'Developer Options',
                          color: Colors.cyan,
                          onTap: () {
                            context.pop();
                            context.push('/settings/developer');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.schedule_rounded,
                          label: 'My Shift',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/shift/dashboard');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.groups_rounded,
                          label: 'Staff Presence',
                          color: AppColors.success,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/staff/presence');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.crisis_alert_rounded,
                          label: 'Alerts',
                          color: AppColors.error,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/manager/alerts');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAccessTile(
                          icon: Icons.person_rounded,
                          label: 'My Profile',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/profile');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
