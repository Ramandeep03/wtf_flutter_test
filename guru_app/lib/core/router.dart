import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../features/auth/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/call/presentation/pages/call_page.dart';
import '../features/call/presentation/pages/post_call_page.dart';
import '../features/call/presentation/pages/pre_join_page.dart';
import '../features/chat/presentation/pages/chat_list_page.dart';
import '../features/chat/presentation/pages/conversation_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/scheduler/presentation/pages/my_requests_page.dart';
import '../features/scheduler/presentation/pages/scheduler_page.dart';
import '../features/sessions/presentation/pages/sessions_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  GoRouterRefreshStream(Stream<dynamic> s) {
    _sub = s.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter buildRouter(AuthCubit authCubit) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (ctx, state) {
        final s = authCubit.state;
        final isLoading = s is ApiLoading || s is ApiInitial;
        final isAuth = s is ApiSuccess<UserEntity>;
        final loc = state.matchedLocation;
        final onSplash = loc == '/splash';
        final onLogin  = loc == '/login';
        final onOnboarding = loc == '/onboarding';

        AppLogger.i(
          LogTag.nav,
          'redirect loc=$loc isAuth=$isAuth isLoading=$isLoading onboarded=$isOnboarded',
        );

        if (isLoading) return onSplash ? null : '/splash';
        if (!isAuth && !onLogin) return '/login';

        // After auth, gate everything except /onboarding behind the
        // onboarding flag. New installs see 2 slides + profile setup once.
        if (isAuth && !isOnboarded && !onOnboarding) return '/onboarding';
        if (isAuth && isOnboarded && onOnboarding) return '/home';
        if (isAuth && (onLogin || onSplash) && isOnboarded) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash',     builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login',      builder: (_, __) => const LoginPage()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        GoRoute(path: '/home',       builder: (_, __) => const HomePage()),
        GoRoute(path: '/chat',      builder: (_, __) => const ChatListPage()),
        GoRoute(path: '/chat/conv', builder: (_, __) => const ConversationPage()),
        GoRoute(path: '/scheduler', builder: (_, __) => const SchedulerPage()),
        GoRoute(path: '/requests',  builder: (_, __) => const MyRequestsPage()),
        GoRoute(
          path: '/pre-join',
          builder: (_, s) => PreJoinPage(
            callRequestId: s.uri.queryParameters['callRequestId'] ?? '',
            role:          s.uri.queryParameters['role'] ?? '',
            memberId:      s.uri.queryParameters['memberId'] ?? '',
            trainerId:     s.uri.queryParameters['trainerId'] ?? '',
          ),
        ),
        GoRoute(path: '/call',      builder: (_, __) => const CallPage()),
        GoRoute(path: '/post-call', builder: (_, s)  => PostCallPage(extra: s.extra)),
        GoRoute(path: '/sessions',  builder: (_, __) => const SessionsPage()),
      ],
    );
