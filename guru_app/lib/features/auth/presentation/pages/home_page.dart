import 'package:flutter/material.dart';

import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../scheduler/presentation/pages/my_requests_page.dart';
import '../../../scheduler/presentation/pages/scheduler_page.dart';
import '../../../sessions/presentation/pages/sessions_page.dart';

/// Tabbed shell for the guru app. Each tab is the existing route page,
/// stacked in an [IndexedStack] so cubit state (request list, session
/// filter, channel-watch listener) survives tab switching.
///
/// The Chats tab's `RoleAppBar` carries the logout button, so the home
/// itself doesn't need a top-level app bar.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _tabs = <Widget>[
    ChatListPage(),
    SchedulerPage(),
    MyRequestsPage(),
    SessionsPage(),
  ];

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
    NavigationDestination(
        icon: Icon(Icons.calendar_today_outlined), label: 'Schedule'),
    NavigationDestination(
        icon: Icon(Icons.event_available_outlined), label: 'Requests'),
    NavigationDestination(icon: Icon(Icons.history), label: 'Sessions'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
