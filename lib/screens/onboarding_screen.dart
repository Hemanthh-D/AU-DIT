import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final pages = [
    {
      "image": "assets/image.png",
      "title": "Welcome to AU-DIT",
      "desc": "AI-powered complaint management for your campus",
    },
    {
      "image": "assets/image.png",
      "title": "Track Complaints",
      "desc": "Real-time updates & technician tracking",
    },
    {
      "image": "assets/image.png",
      "title": "Fast Resolution",
      "desc": "Get issues resolved quickly & efficiently",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 SKIP
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text("Skip"),
                ),
              ),
            ),

            // 📱 PAGES
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      double value = 1.0;

                      if (_controller.position.haveDimensions) {
                        value = _controller.page! - index;
                        value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                      }

                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🖼 IMAGE
                                Expanded(
                                  child: Image.asset(
                                    page["image"]!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image, size: 100),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // 📝 TITLE
                                Text(
                                  page["title"]!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),

                                const SizedBox(height: 10),

                                // 📄 DESCRIPTION
                                Text(
                                  page["desc"]!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 🔘 DOT INDICATOR
            SmoothPageIndicator(
              controller: _controller,
              count: pages.length,
              effect: WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: scheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // 🚀 BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: () {
                    if (currentIndex == pages.length - 1) {
                      context.go('/login');
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    currentIndex == pages.length - 1 ? "Get Started" : "Next",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
