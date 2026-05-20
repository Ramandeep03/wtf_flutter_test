import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../features/auth/presentation/pages/home_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/members_page.dart';
import '../features/call/presentation/pages/call_page.dart';
import '../features/call/presentation/pages/post_call_page.dart';
import '../features/call/presentation/pages/pre_join_page.dart';
import '../features/chat/presentation/pages/chat_list_page.dart';
import '../features/chat/presentation/pages/conversation_page.dart';
import '../features/requests/presentation/pages/requests_page.dart';
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
        final onSplash = state.matchedLocation == '/splash';
        final onLogin  = state.matchedLocation == '/login';

        if (isLoading) return onSplash ? null : '/splash';
        if (!isAuth && !onLogin) return '/login';
        if (isAuth && (onLogin || onSplash)) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash',    builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login',     builder: (_, __) => const LoginPage()),
        GoRoute(path: '/home',      builder: (_, __) => const HomePage()),
        GoRoute(path: '/members',   builder: (_, __) => const MembersPage()),
        GoRoute(path: '/chat',      builder: (_, __) => const ChatListPage()),
        GoRoute(path: '/chat/conv', builder: (_, __) => const ConversationPage()),
        GoRoute(path: '/requests',  builder: (_, __) => const RequestsPage()),
        GoRoute(
          path: '/pre-join',
          builder: (_, s) => PreJoinPage(
            roomId: s.uri.queryParameters['roomId'] ?? '',
            role:   s.uri.queryParameters['role'] ?? '',
          ),
        ),
        GoRoute(path: '/call',      builder: (_, __) => const CallPage()),
        GoRoute(path: '/post-call', builder: (_, s)  => PostCallPage(extra: s.extra)),
        GoRoute(path: '/sessions',  builder: (_, __) => const SessionsPage()),
      ],
    );
