import 'package:flutter/material.dart';
import '../theme_notifier.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen>
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
                'Terms & Conditions',
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
                        '1. General Information',
                        'The website and brand are operated by BEINN.\n\nBy using our services, you confirm that you are at least 18 years old or have parental/guardian consent.\n\nWe reserve the right to update, modify, or replace any part of these Terms at any time.',
                      ),
                      _buildSection(
                        '2. Products & Services',
                        'We strive to provide accurate product descriptions, images, and pricing. However, slight variations in colors, textures, or sizes may occur.\n\nBEINN reserves the right to discontinue or modify products without prior notice.\n\nAll products are subject to availability.',
                      ),
                      _buildSection(
                        '3. Orders & Payments',
                        'By placing an order, you agree to provide accurate billing and shipping details.\n\nWe accept various payment methods, as displayed at checkout.\n\nBEINN reserves the right to cancel or refuse orders in cases of suspected fraud, incorrect pricing, or stock unavailability.',
                      ),
                      _buildSection(
                        '4. Shipping & Delivery',
                        'Estimated delivery times are provided for convenience and may vary due to external factors.\n\nBEINN is not responsible for delays caused by third-party couriers, customs, or unforeseen circumstances.\n\nShipping fees, taxes, and duties may apply depending on your location.',
                      ),
                      _buildSection(
                        '5. Returns & Refunds',
                        'BEINN accepts returns/exchanges within 48 hours of delivery, subject to conditions.\n\nItems must be unworn, unwashed, and in their original packaging with tags attached.\n\nRefunds will be processed to the original payment method after inspection.\n\nCertain products may not be eligible for return.',
                      ),
                      _buildSection(
                        '6. Intellectual Property',
                        'All website content, logos, images, and designs are the intellectual property of BEINN.\n\nYou may not reproduce, modify, or use our intellectual property without written consent.',
                      ),
                      _buildSection(
                        '7. User Conduct',
                        'You agree not to:\n• Use the website for unlawful purposes.\n• Interfere with website functionality or attempt unauthorized access.\n• Misuse product reviews, comments, or customer support services.',
                      ),
                      _buildSection(
                        '8. Limitation of Liability',
                        'BEINN is not liable for indirect, incidental, or consequential damages arising from your use of our products or services.\n\nOur total liability for any claim shall not exceed the amount paid for the product in question.',
                      ),
                      _buildSection(
                        '9. Privacy Policy',
                        'Your use of our website is also governed by our Privacy Policy, which outlines how we collect and use your information.',
                      ),
                      _buildSection(
                        '10. Governing Law',
                        'These Terms are governed by the laws of India.\n\nAny disputes shall be resolved in the courts of Jurisdiction.',
                      ),
                      _buildSection(
                        '11. Contact Us',
                        'If you have questions regarding these Terms & Conditions, please contact us:\n\nBEINN – Customer Support\n📧 Email: beinnlifestyle@gmail.com',
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
