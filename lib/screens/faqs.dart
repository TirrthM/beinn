import 'package:flutter/material.dart';
import '../theme_notifier.dart';

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({Key? key}) : super(key: key);

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Processing Time',
      'answer':
          'Orders are typically processed within 1–3 business days after payment confirmation.\n\nOrders placed on weekends or public holidays will be processed on the next business day.',
    },
    {
      'question': 'Shipping Methods & Delivery Time',
      'answer':
          'We partner with trusted carriers to ensure timely delivery. Estimated delivery times are:\n\n• Domestic Shipping (Within India): 5-7 business days\n• International Shipping: 15–20 business days, depending on location\n\nNote: Delivery times may vary due to customs clearance, courier delays, or other unforeseen circumstances.',
    },
    {
      'question': 'Shipping Costs',
      'answer':
          'Shipping fees are calculated at checkout based on your location and order size.\n\nFree shipping may be available on orders above ₹500.',
    },
    {
      'question': 'Order Tracking',
      'answer':
          'Once your order is shipped, you will receive a confirmation email with a tracking number.\n\nYou can track your order using the provided link or directly through the courier\'s website.',
    },
    {
      'question': 'International Shipping',
      'answer':
          'International orders may be subject to customs duties, taxes, or import fees imposed by your local government.\n\nThese charges are the customer\'s responsibility and are not included in BEINN\'s shipping fees.',
    },
    {
      'question': 'Undeliverable Packages',
      'answer':
          'If a package is returned due to an incorrect address, failed delivery attempts, or refusal to pay customs duties, the customer will be responsible for re-shipping costs.',
    },
    {
      'question': 'Damaged or Lost Packages',
      'answer':
          'BEINN is not responsible for delays or lost packages once the order is handed over to the courier.\n\nIf your package arrives damaged, please contact us within 48 hours with photos, and we will assist you.',
    },
  ];

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
                    // AppBar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      color: isDark
                          ? Colors.black
                          : const Color.fromARGB(255, 250, 249, 245),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[900] : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: isDark
                                    ? null
                                    : Border.all(
                                        color: Colors.grey[300]!, width: 1),
                              ),
                              child: Icon(Icons.arrow_back,
                                  color: isDark ? Colors.white : Colors.black,
                                  size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'FAQs',
                              style: TextStyle(
                                color: orange,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Frequently Asked Questions',
                              style: TextStyle(
                                color: orange,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find answers to common shipping and delivery questions',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ..._faqs.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, String> faq = entry.value;
                              return _buildFAQItem(
                                index: index,
                                question: faq['question']!,
                                answer: faq['answer']!,
                                isDark: isDark,
                              );
                            }),
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

  Widget _buildFAQItem({
    required int index,
    required String question,
    required String answer,
    required bool isDark,
  }) {
    const orange = Color(0xFFBB694A);
    bool isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpanded
            ? orange.withOpacity(0.05)
            : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? orange.withOpacity(0.3)
              : (isDark ? Colors.grey[850]! : Colors.grey[300]!),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
          splashColor: orange.withOpacity(.08),
          highlightColor: orange.withOpacity(.05),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        question,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: orange,
                      size: 24,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? Colors.grey[850] : Colors.grey[200],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    answer,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
