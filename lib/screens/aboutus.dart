import 'package:flutter/material.dart';
import '../theme_notifier.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFBB694A);

    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor: isDark
              ? Colors.black
              : const Color.fromARGB(255, 250, 249, 245), // #FAF9F5
          body: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black
                            : const Color.fromARGB(255, 250, 249, 245),
                        border: Border(
                          bottom: BorderSide(
                              color: isDark
                                  ? Colors.grey[900]!
                                  : Colors.grey[300]!,
                              width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.transparent
                                        : Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: isDark ? Colors.white : Colors.black,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'About Us',
                            style: TextStyle(
                              color: orange,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildContentSection(
                              title: 'Our Vision',
                              subtitle: 'Clarity Through Simplicity',
                              content:
                                  'At BEINN, we believe life becomes clearer when you remove the noise. Our journey began with a simple yet powerful idea—that true strength, confidence, and growth come from simplicity. In a world full of distractions, trends, and fleeting fashions, we wanted to create something timeless. Something that doesn\'t just fit into your wardrobe, but fits into your life.',
                            ),
                            const SizedBox(height: 28),
                            _buildContentSection(
                              title: 'How BEINN Was Born',
                              subtitle: 'More Than Clothing',
                              content:
                                  'BEINN was born from this belief. We design clothes that go beyond clothing—pieces that strip away excess and allow you to focus on what truly matters. Each garment is created to remind you of the values that build a better life: discipline, balance, and joy. When you wear BEINN, you\'re not just wearing apparel. You\'re wearing a mindset.',
                            ),
                            const SizedBox(height: 28),
                            _buildContentSection(
                              title: 'Our Philosophy',
                              subtitle: 'Simplicity Fuels Strength',
                              content:
                                  'We believe that simplicity fuels strength. Our designs are intentionally minimal, yet deeply meaningful. They are crafted to provide both comfort and confidence, adapting effortlessly to every environment—whether you\'re working, creating, or simply enjoying the present moment. By removing distractions, BEINN helps you stay centered and channel your energy toward what\'s important.',
                            ),
                            const SizedBox(height: 28),
                            _buildContentSection(
                              title: 'Our Commitment',
                              subtitle: 'Building a Community',
                              content:
                                  'As we continue to grow, our mission remains the same: to create clothing that empowers you to live with focus, discipline, and joy. We are more than a brand. We are a community built on the belief that simplicity is not just beautiful—it\'s powerful.',
                            ),
                            const SizedBox(height: 28),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: orange.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'BEINN Isn\'t Just Clothing',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'It\'s a lifestyle.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: orange,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'A lifestyle that keeps you centered, confident, and always moving forward.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[300]
                                          : Colors.grey[800],
                                      fontSize: 14,
                                      height: 1.6,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentSection({
    required String title,
    required String subtitle,
    required String content,
  }) {
    const orange = Color(0xFFBB694A);

    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              Text(
                title,
                style: const TextStyle(
                  color: orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Content Text
              Text(
                content,
                style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.7,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );
        });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
