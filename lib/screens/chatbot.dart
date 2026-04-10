import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../data/products_data.dart';
import '../theme_notifier.dart';

import 'package:shared_preferences/shared_preferences.dart'; // For rate limiting

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Groq Configuration
  static const String _apiKey =
      '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'; // Groq API Key
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Rate Limiting Configuration
  static const int _hourlyMessageLimit = 10; // Limit per user per hour

  final List<String> _funGreetings = [
    "Ready to upgrade your wardrobe? 👗✨",
    "Looking for the perfect fit today? 🧐👕",
    "Let's find you something stylish! 🔥",
    "Need help picking a color? 🎨",
    "Fresh drops are waiting for you! 🚀",
  ];

  @override
  void initState() {
    super.initState();
    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    setState(() {
      // 1. Standard Greeting
      _messages.add(ChatMessage(
        text:
            "Hello! I'm your BEINN assistant. Ask me anything about our clothing, policies or products!",
        isUser: false,
      ));

      // 2. Random Fun Greeting
      final random = Random();
      final funGreeting = _funGreetings[random.nextInt(_funGreetings.length)];
      _messages.add(ChatMessage(
        text: funGreeting,
        isUser: false,
      ));
    });
  }

  // Check if user has exceeded their hourly limit
  Future<bool> _checkHourlyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> timestamps =
        prefs.getStringList('chat_timestamps') ?? [];
    final now = DateTime.now();

    // Filter: Keep only timestamps from the last 30 minutes
    final validTimestamps = timestamps.where((ts) {
      final time = DateTime.parse(ts);
      return now.difference(time).inMinutes < 30;
    }).toList();

    if (validTimestamps.length >= _hourlyMessageLimit) {
      return false; // Limit reached
    }

    // Add current time and save
    validTimestamps.add(now.toIso8601String());
    await prefs.setStringList('chat_timestamps', validTimestamps);
    return true;
  }

  // This function simulates "scanning" the app by aggregating data from data sources and hardcoded policies
  String _generateAppScanningContext() {
    final StringBuffer buffer = StringBuffer();

    // 1. System Identity and Strict Rules
    buffer.writeln(
        "You are a helpful, cool, and friendly AI assistant for 'BEINN', a trendy clothing brand.");
    buffer.writeln("STRICT RESPONSE GUIDELINES:");
    buffer.writeln(
        "1. FORMATTING: Use standard Markdown lists. Start each item with a dash (- ) and a space. Put EVERY item on a NEW LINE.");
    buffer.writeln(
        "2. BOLDING: You MUST use **double stars** for product names and headings. Example: - **Acid Wash Tee**");
    buffer.writeln(
        "3. TONE: Be warm and engaging. Use relevant EMOJIS (✨, 👕, 🔥) sparingly.");
    buffer.writeln(
        "4. SCOPE: ONLY answer questions about BEINN products, style, policies, and orders.");
    buffer.writeln("- Use the provided context below to answer accurately.");

    // 2. Scan Products
    buffer.writeln("\n=== PRODUCT INVENTORY SCAN ===");
    final allProducts = ProductsData.getAllProducts();
    for (var product in allProducts) {
      buffer.writeln("ID: ${product.id}");
      buffer.writeln("Name: ${product.name}");
      buffer.writeln("Category: ${product.category}");
      buffer.writeln(
          "Price: ${product.price} (Original: ${product.originalPrice})");
      buffer.writeln("Discount: ${product.discount}");
      buffer.writeln("Colors: ${product.colors.join(', ')}");
      buffer.writeln("Sizes: ${product.sizes.join(', ')}");
      buffer.writeln("Description: ${product.description}");
      buffer.writeln(
          "Wash Care: ${product.washCare?.replaceAll('\n', ' ') ?? 'None'}"); // Flatten for easier reading
      buffer.writeln("---");
    }

    // 3. Scan Policies (Simplified)
    buffer.writeln("\n=== RULES & POLICIES ===");
    buffer.writeln(
        "Privacy: We collect basic info (name, email, address) for orders/support. No selling data.");
    buffer.writeln("Cookies: Used for preferences.");
    buffer.writeln("Contact: beinnlifestyle@gmail.com");

    buffer.writeln(
        "Shipping: 3-5 days processing. Domestic 5-7 days. Intl 7-14 days. Free >₹500.");
    buffer.writeln("Returns: Contact within 24hrs for damaged goods.");

    buffer.writeln("\n=== END ===");
    return buffer.toString();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Check hourly limit BEFORE processing
    final canConvert = await _checkHourlyLimit();
    if (!canConvert) {
      setState(() {
        _messages.add(ChatMessage(text: text, isUser: true)); // Show user msg
        _messages.add(ChatMessage(
            text:
                "You have reached the limit of $_hourlyMessageLimit messages every 30 minutes. Please take a break and try again later! 🕒",
            isUser: false));
      });
      _controller.clear();
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final String systemContext = _generateAppScanningContext();

      // Construct the message history for context, but limit to last 6 messages to avoid hitting token limits efficiently
      List<Map<String, String>> apiMessages = [
        {"role": "system", "content": systemContext},
      ];

      // Add recent chat history (simple memory)
      // Actually, let's just send System + Current User Message for robustness given the prompt size.
      apiMessages.add({"role": "user", "content": text});

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "messages": apiMessages,
          "model":
              "llama-3.1-8b-instant", // FAST, reliable, and active model. Good rate limits.
          "temperature": 0.5,
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add(ChatMessage(text: reply, isUser: false));
          _isLoading = false;
        });
      } else if (response.statusCode == 429) {
        // Handle Rate Limiting Gracefully
        setState(() {
          _messages.add(ChatMessage(
              text:
                  "I'm receiving too many requests right now! 😅 Please wait a moment and try again.",
              isUser: false));
          _isLoading = false;
        });
      } else {
        // Show the actual API error message in the chat
        final errorBody = response.body;
        throw Exception("Status ${response.statusCode}: $errorBody");
      }
    } catch (e) {
      setState(() {
        _messages.add(
            ChatMessage(text: "Error: $e", isUser: false)); // Show actual error
        _isLoading = false;
      });
      print('Groq/Network Error Details: $e');
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, child) {
        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  color: isDark ? Colors.white : Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Text(
              'BEINN Assistant',
              style: TextStyle(
                color: const Color(0xFFBB694A), // Orange color as requested
                fontSize: 22, // Bigger
                fontWeight: FontWeight.bold, // Bold
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: Stack(
            children: [
              // Chat List (Content Layer)
              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      // Add substantial bottom padding so the last message isn't hidden by the floating bar
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _buildMessageBubble(message, isDark);
                      },
                    ),
                  ),
                ],
              ),

              // Loading Indicator (Above content, below input)
              if (_isLoading)
                Positioned(
                  bottom: 100, // Just above input bar
                  left: 20,
                  child: _buildTypingIndicator(isDark),
                ),

              // Floating Input Bar (Top Layer with Blur)
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildInputArea(isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(const Color(0xFFBB694A)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Thinking...",
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;
    final bgColor = isUser
        ? const Color(0xFFBB694A)
        : (isDark ? const Color(0xFF2C2C2C) : Colors.white);
    final textColor = isUser
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1F1F1F));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        // Use MarkdownBody to render **bold** text correctly
        child: MarkdownBody(
          data: message.text,
          styleSheet: MarkdownStyleSheet(
            // General text style
            p: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
            // Bold text style
            strong: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            // List styling (bullet points)
            listBullet: TextStyle(
              color: textColor,
              fontSize: 15,
            ),
            // Spacing adjustments
            blockSpacing: 8.0,
            listIndent: 20.0,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    // Meta AI / Whatsapp style: Input field contains the attach icon (optional) and the send button is separate or integrated.
    // The user specifically asked to "Take the logo... and keep it with the send button".
    // So we will put the Sparkles icon on the RIGHT side, replacing or next to the Send Icon.
    // Actually, on WhatsApp, the Meta AI circle is a floating button or special entry.
    // User request: "keep it with the send button".
    // Let's create a slick input bar with the text field and a gradient toggle button that has the AI icon.

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 30), // Extra bottom padding
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF121212) : const Color(0xFFF7F7F7))
                .withOpacity(0.8), // Semi-transparent for blur effect
          ),
          child: Container(
            padding:
                const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(30), // Capsule shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Align bottom for multi-line
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 100, // Limit to approx 4-5 lines then scroll
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: null, // Grow vertically
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask Beinn Assistant...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Small Send Button inside the capsule
                Container(
                  margin: const EdgeInsets.only(
                      bottom: 6), // Align with last line of text
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFBB694A),
                    radius: 18, // Smaller button
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
