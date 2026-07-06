import 'package:flutter/material.dart';
import '../theme_notifier.dart';

class RefundPolicyScreen extends StatefulWidget {
  const RefundPolicyScreen({super.key});

  @override
  State<RefundPolicyScreen> createState() => _RefundPolicyScreenState();
}

class _RefundPolicyScreenState extends State<RefundPolicyScreen>
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
                'Refund Policy',
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
                        'At BEINN, we value your satisfaction and want you to love your purchase. If for any reason you are not completely happy with your order, our Refund & Return Policy makes the process simple and transparent.',
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        '1. Eligibility for Returns',
                        'Returns are accepted within 48 hours of delivery.\n\nItems must be:\n• Unworn and unwashed.\n• In their original condition with tags and packaging intact.\n• Free from stains, perfumes, or alterations.\n\nCertain items are non-returnable, including:\n• Final sale or clearance items.\n• Customized/personalized products.',
                      ),
                      _buildSection(
                        '2. Refund Process',
                        'Once your return is received and inspected, we will notify you of the approval or rejection of your refund.\n\nIf approved, refunds will be issued to your original payment method within 7-10 business days.\n\nShipping charges, duties, and taxes are non-refundable unless the return is due to our error (e.g., wrong or defective item).',
                      ),
                      _buildSection(
                        '3. Exchanges',
                        'We offer exchanges for different sizes or colors of the same product (subject to stock availability).\n\nIf the requested item is unavailable, a refund will be processed instead.',
                      ),
                      _buildSection(
                        '4. Defective or Wrong Items',
                        'If you receive a defective, damaged, or incorrect item, please contact us within 24 hours of delivery.\n\nWe will arrange a replacement or full refund at no additional cost.',
                      ),
                      _buildSection(
                        '5. Return Shipping',
                        'Customers are responsible for return shipping costs unless the return is due to our error.\n\nWe recommend using a trackable shipping service to ensure your item reaches us.',
                      ),
                      _buildSection(
                        '6. How to Initiate a Return',
                        'To start a return or exchange, please contact our support team with your order details:\n\nBEINN – Customer Support\n📧 Email: beinnlifestyle@gmail.com\n\nOur team will guide you through the next steps.',
                      ),
                      _buildSection(
                        '7. Policy Updates',
                        'We may update this Refund Policy from time to time. Please review it periodically for changes.',
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
