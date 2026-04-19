import 'package:flutter/material.dart';

/// Data model for each onboarding step
class OnboardingData {
  final String title;
  final String subtitle;
  final String imagePath; // kept for backward compat, but illustration is preferred
  final Widget? illustration; // Flutter-drawn illustration widget

  const OnboardingData({
    required this.title,
    this.subtitle = '',
    this.imagePath = '',
    this.illustration,
  });
}

/// Reusable onboarding page view with swipeable pages,
/// dot indicators, back/menu buttons, and action buttons.
class OnboardingScreen extends StatefulWidget {
  final List<OnboardingData> pages;
  final VoidCallback onFinish;
  final VoidCallback? onSkip;
  final String finishButtonText;
  final String skipButtonText;
  final bool showBackButton;
  final bool showMenuButton;

  const OnboardingScreen({
    super.key,
    required this.pages,
    required this.onFinish,
    this.onSkip,
    this.finishButtonText = "Let's Begin",
    this.skipButtonText = 'Skip Step',
    this.showBackButton = true,
    this.showMenuButton = true,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back arrow & menu
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showBackButton)
                    GestureDetector(
                      onTap: _goBack,
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2D2D2D),
                        size: 24,
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // Page content (swipeable)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = widget.pages[index];
                  return _OnboardingPageContent(data: page);
                },
              ),
            ),

            // Dot indicator
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
              child: _DotIndicator(
                count: widget.pages.length,
                currentIndex: _currentPage,
              ),
            ),

            // "Let's Begin" button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < widget.pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      widget.onFinish();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D6D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(widget.finishButtonText),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // "Skip Step" button
            GestureDetector(
              onTap: widget.onSkip ?? widget.onFinish,
              child: Text(
                widget.skipButtonText,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Single page content (illustration + title + subtitle)
class _OnboardingPageContent extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Illustration area — use custom widget if provided, else fall back to PNG
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: data.illustration ??
                  (data.imagePath.isNotEmpty
                      ? Image.asset(data.imagePath, fit: BoxFit.contain)
                      : const SizedBox()),
            ),
          ),

          // Divider line
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 28),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
              height: 1.2,
            ),
          ),

          if (data.subtitle.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// Dot indicator widget
class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _DotIndicator({
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 12 : 10,
          height: isActive ? 12 : 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFFFF4D6D)
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
