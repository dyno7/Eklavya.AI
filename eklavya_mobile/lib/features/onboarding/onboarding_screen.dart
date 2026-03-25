import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_background.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/glow_icon.dart';

/// 3-page swipeable onboarding intro.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onComplete() {
    context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardingPage(
        icon: Icons.smart_toy_rounded,
        iconColor: context.colors.primary,
        title: 'Meet Your Guru',
        description:
            'Your AI companion creates personalized roadmaps\n'
            'tailored to your goals across any domain.',
      ),
      _OnboardingPage(
        icon: Icons.trending_up_rounded,
        iconColor: context.colors.accent,
        title: 'Track Your Progress',
        description:
            'Earn XP, unlock badges, and maintain streaks\n'
            'as you conquer milestones every day.',
      ),
      _OnboardingPage(
        icon: Icons.psychology_rounded,
        iconColor: context.colors.secondary,
        title: 'Stay Consistent',
        description:
            'An adaptive AI coach detects drift and adjusts\n'
            'your plan to keep you on track.',
      ),
    ];

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ─── Skip button ───
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: _currentPage < 2
                      ? TextButton(
                          onPressed: () => _goToPage(2),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : SizedBox(height: 48),
                ),
              ),

              // ─── Page content ───
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlowIcon(
                            icon: page.icon,
                            color: page.iconColor,
                            size: 80,
                            glowRadius: 32,
                          ),
                          SizedBox(height: AppSpacing.xxxl),
                          Text(
                            page.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            page.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: context.colors.textSecondary,
                                  height: 1.6,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                          .animate(key: ValueKey(index))
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.15, end: 0, duration: 500.ms),
                    );
                  },
                ),
              ),

              // ─── Dots + button ───
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? context.colors.primary
                                : context.colors.textTertiary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: AppSpacing.xxl),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        label:
                            _currentPage == 2 ? 'Get Started' : 'Next',
                        onPressed: _currentPage == 2
                            ? _onComplete
                            : () => _goToPage(_currentPage + 1),
                        icon: _currentPage == 2
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
}
