import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared/shared.dart';

/// Hive key that gates the onboarding redirect. Lives in 'app_prefs'
/// alongside the auth id token.
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish() async {
    await Hive.box('app_prefs').put(onboardedKey, true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _Slide(
                    icon: Icons.fitness_center,
                    title: 'Welcome to WTF Fitness',
                    body:
                        'Train with a personal coach over secure video calls. '
                        'Schedule sessions, chat with your trainer, and track every workout.',
                  ),
                  _Slide(
                    icon: Icons.video_call_outlined,
                    title: 'Stay accountable',
                    body:
                        'Get a notification before each session, join the call '
                        'in one tap, and review your notes afterwards.',
                  ),
                  _ProfileSetup(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _DotsIndicator(count: 3, active: _page),
                  const Spacer(),
                  if (_page < 2)
                    TextButton(onPressed: _finish, child: const Text('Skip'))
                  else
                    const SizedBox.shrink(),
                  if (_page < 2)
                    ElevatedButton(
                      onPressed: _next,
                      child: const Text('Next'),
                    )
                  else
                    _ProfileSubmitButton(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: AppColors.guruPrimary),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: AppTypography.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
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

// ─── Profile setup (final page) ──────────────────────────────────────────

class _ProfileSetup extends StatefulWidget {
  const _ProfileSetup();

  @override
  State<_ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<_ProfileSetup> {
  late final TextEditingController _nameCtrl;
  String? _trainerId;
  List<UserEntity>? _trainers;
  String? _trainersError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().state.userOrNull;
    _nameCtrl = TextEditingController(text: user?.name ?? 'DK');
    _trainerId = user?.assignedTrainerId;
    _loadTrainers();
  }

  Future<void> _loadTrainers() async {
    try {
      final raw = await ApiClient.instance.getList('/users');
      final trainers = raw
          .cast<Map<String, dynamic>>()
          .where((m) => (m['role'] as String?) == 'trainer')
          .map(UserEntity.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _trainers = trainers;
        _trainerId ??= trainers.isNotEmpty ? trainers.first.uid : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _trainersError = e.toString());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Text('Set up your profile',
              style: AppTypography.h1, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Confirm your name and choose your coach.',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_trainersError != null)
            Text(
              'Couldn\'t load trainers: $_trainersError',
              style: const TextStyle(color: AppColors.error),
            )
          else if (_trainers == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _trainerId,
              decoration: const InputDecoration(
                labelText: 'Your trainer',
                border: OutlineInputBorder(),
              ),
              items: _trainers!
                  .map((t) => DropdownMenuItem(
                        value: t.uid,
                        child: Text(t.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _trainerId = v),
            ),
        ],
      ),
    );
  }
}

class _ProfileSubmitButton extends StatelessWidget {
  final VoidCallback onFinish;
  const _ProfileSubmitButton({required this.onFinish});

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: onFinish,
        child: const Text('Get started'),
      );
}
