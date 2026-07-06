import 'package:flutter/material.dart';
import '../theme_notifier.dart';

class ShippingReturnsScreen extends StatefulWidget {
  const ShippingReturnsScreen({super.key});

  @override
  State<ShippingReturnsScreen> createState() => _ShippingReturnsScreenState();
}

class _ShippingReturnsScreenState extends State<ShippingReturnsScreen>
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
                'Shipping & Returns',
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
                        'At BEINN, we aim to deliver your favorite clothing items quickly and safely. This Shipping Policy explains how we process and deliver your orders.',
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        '1. Processing Time',
                        'Orders are typically processed within 3-5 business days after payment confirmation.\n\nOrders placed on weekends or public holidays will be processed on the next business day.',
                      ),
                      _buildSection(
                        '2. Shipping Methods & Delivery Time',
                        'We partner with trusted carriers to ensure timely delivery. Estimated delivery times are:\n\n• Domestic Shipping: 5-7 business days.\n• International Shipping: 7–14 business days, depending on location.\n\nNote: Delivery times may vary due to customs clearance, courier delays, or other unforeseen circumstances.',
                      ),
                      _buildSection(
                        '3. Shipping Costs',
                        'Shipping fees are calculated at checkout based on your location and order size.\n\nFree shipping may be available on orders above ₹500.',
                      ),
                      _buildSection(
                        '4. Order Tracking',
                        'Once your order is shipped, you will receive a confirmation email with a tracking number.\n\nYou can track your order using the provided link or directly through the courier\'s website.',
                      ),
                      _buildSection(
                        '5. International Shipping',
                        'International orders may be subject to customs duties, taxes, or import fees imposed by your local government.\n\nThese charges are the customer\'s responsibility and are not included in BEINN\'s shipping fees.',
                      ),
                      _buildSection(
                        '6. Undeliverable Packages',
                        'If a package is returned due to an incorrect address, failed delivery attempts, or refusal to pay customs duties, the customer will be responsible for re-shipping costs.',
                      ),
                      _buildSection(
                        '7. Damaged or Lost Packages',
                        'BEINN is not responsible for delays or lost packages once the order is handed over to the courier.\n\nIf your package arrives damaged, please contact us within 24 hours with photos, and we will assist you.',
                      ),
                      _buildSection(
                        '8. Contact Us',
                        'For questions regarding shipping, please contact:\n\nBEINN – Customer Support\n📧 Email: beinnlifestyle@gmail.com',
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
