import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';

const String onboardedKey = 'onboarded';

bool get isOnboarded =>
    Hive.box('app_prefs').get(onboardedKey, defaultValue: false) as bool;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(
      icon: Icons.fitness_center,
      title: 'Welcome to WTF Fitness',
      body: 'Train with a personal coach over secure video calls. '
          'Schedule sessions, chat with your trainer, and track every workout.',
    ),
    _SlideData(
      icon: Icons.video_call_outlined,
      title: 'Stay accountable',
      body: 'Get a notification before each session, join the call '
          'in one tap, and review your notes afterwards.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    await Hive.box('app_prefs').put(onboardedKey, true);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _slides.map((s) => _Slide(data: s)).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _DotsIndicator(count: _slides.length, active: _page),
                  const Spacer(),
                  if (!isLast)
                    TextButton(onPressed: _finish, child: const Text('Skip')),
                  ElevatedButton(
                    onPressed: isLast ? _finish : _next,
                    child: Text(isLast ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String body;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _Slide extends StatelessWidget {
  final _SlideData data;
  const _Slide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 96, color: AppColors.guruPrimary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            data.title,
            style: AppTypography.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.body,
            style: AppTypography.body
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int active;
  const _DotsIndicator({required this.count, required this.active});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final isActive = i == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            height: 8,
            width: isActive ? 24 : 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.guruPrimary
                  : AppColors.borderLight,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
}
