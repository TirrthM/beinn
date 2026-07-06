import 'package:flutter/material.dart';
import '../theme_notifier.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Scaffold(
            backgroundColor: isDark
                ? Colors.black
                : const Color.fromARGB(255, 250, 249, 245), // #FAF9F5
            appBar: AppBar(
              backgroundColor: isDark
                  ? Colors.black
                  : const Color.fromARGB(255, 250, 249, 245),
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isDark
                        ? null
                        : Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : Colors.black, size: 18),
                ),
              ),
              title: const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Color(0xFFBB694A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntroSection(
                        'At BEINN, your privacy is our priority. This Privacy Policy explains how we collect, use, and safeguard your personal information when you visit our website, shop with us, or interact with our brand. By using our services, you agree to the terms of this Privacy Policy.',
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        '1. Information We Collect',
                        'We may collect the following types of information:\n\n• Personal Information: Name, email address, phone number, billing/shipping address, and payment details.\n• Account Information: Login credentials and order history if you create an account with us.\n• Usage Data: Information about how you interact with our website (pages visited, time spent, IP address, device type, browser).\n• Marketing Preferences: Your choices regarding receiving promotional offers, newsletters, or updates.',
                      ),
                      _buildSection(
                        '2. How We Use Your Information',
                        'We use your data to:\n\n• Process and fulfill your orders.\n• Provide customer service and support.\n• Personalize your shopping experience.\n• Send order updates, promotional offers, and newsletters (if you opt-in).\n• Improve our website, products, and services.\n• Comply with legal and regulatory obligations.',
                      ),
                      _buildSection(
                        '3. Sharing of Information',
                        'We do not sell or rent your personal information. However, we may share it with:\n\n• Service Providers: For payment processing, shipping, IT support, and marketing services.\n• Legal Authorities: If required by law or to protect our rights.\n• Business Transfers: In case of a merger, acquisition, or restructuring of BEINN.',
                      ),
                      _buildSection(
                        '4. Cookies and Tracking',
                        'We use cookies and similar technologies to:\n\n• Remember your preferences.\n• Enhance website functionality.\n• Analyze traffic and shopping behavior.\n\nYou can manage or disable cookies in your browser settings, though some features may not work properly.',
                      ),
                      _buildSection(
                        '5. Data Security',
                        'We take appropriate measures to protect your personal data from unauthorized access, alteration, or disclosure. However, no method of transmission over the Internet or electronic storage is 100% secure.',
                      ),
                      _buildSection(
                        '6. Your Rights',
                        'Depending on your location, you may have the right to:\n\n• Access, update, or delete your personal data.\n• Opt-out of marketing communications.\n• Request a copy of your personal data.\n• Withdraw consent for certain data uses.',
                      ),
                      _buildSection(
                        '7. Third-Party Links',
                        'Our website may contain links to third-party sites. We are not responsible for the privacy practices of these websites and encourage you to read their privacy policies.',
                      ),
                      _buildSection(
                        '8. Children\'s Privacy',
                        'Our services are not directed to individuals under the age of 13. We do not knowingly collect personal information from children.',
                      ),
                      _buildSection(
                        '9. Changes to This Policy',
                        'We may update this Privacy Policy from time to time. Changes will be posted on this page with an updated Effective Date.',
                      ),
                      _buildSection(
                        '10. Contact Us',
                        'If you have questions about this Privacy Policy or how we handle your data, please contact us:\n\nBEINN – Customer Support\n📧 Email: beinnlifestyle@gmail.com',
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  Widget _buildIntroSection(String content) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[800],
                fontSize: 14,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        });
  }

  Widget _buildSection(String title, String content) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFBB694A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          );
        });
  }
}
