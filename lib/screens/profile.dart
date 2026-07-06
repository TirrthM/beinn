import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_addresses.dart';
import 'edit_profile.dart';
import 'aboutus.dart';
import 'privacypolicy.dart';
import 'shippingreturns.dart';
import 'refundpolicy.dart';
import 'termsconditions.dart';
import 'faqs.dart';
import '../theme_notifier.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // Animations
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  // User fields
  String _fullName = '';
  String _email = '';
  String _mobile = '';
  String _gender = '';
  String _address = '';

  bool _loading = true;
  bool _isAuthInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _waitForAuthAndLoadProfile();
  }

  void _waitForAuthAndLoadProfile() {
    final user = _auth.currentUser;

    if (user != null && mounted) {
      _isAuthInitialized = true;
      _listenUserProfile();
    } else {
      // Wait a moment for auth to be fully initialized, then try again
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _auth.currentUser != null && !_isAuthInitialized) {
          _isAuthInitialized = true;
          _listenUserProfile();
        } else if (mounted && _auth.currentUser == null) {
          setState(() => _loading = false);
        }
      });
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _listenUserProfile() {
    final user = _auth.currentUser;

    if (mounted) {
      setState(() {
        _email = user?.email ?? '';
        _loading = true;
      });
    }

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    _profileSub?.cancel();

    _profileSub =
        _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
      if (!mounted) return;

      final data = doc.data() ?? {};

      final first = _clean(data['firstName']) ?? _clean(data['firstname']);
      final last = _clean(data['lastName']) ?? _clean(data['lastname']);
      final combined = _combineName(first, last);

      final emailFromDb =
          _clean(data['email']) ?? _clean(data['mail']) ?? _email;

      final mobile = _clean(data['mobile']) ??
          _clean(data['phone']) ??
          _clean(data['phoneNumber']) ??
          '';

      final gender = _normalizeGender(_clean(data['gender']));

      // Address can be:
      // - String in 'address'
      // - Map in 'address' with building/area/landmark/city/state/pincode
      // - Nested under 'deliveryAddress.address'
      final address = _extractAddress(data);

      if (mounted) {
        setState(() {
          _fullName = combined;
          _email = emailFromDb;
          _mobile = mobile ?? '';
          _gender = gender;
          _address = address;
          _loading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Profile listen error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  String? _clean(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  String _combineName(String? first, String? last) {
    final parts = <String>[];
    if (first != null && first.isNotEmpty) parts.add(first);
    if (last != null && last.isNotEmpty) parts.add(last);
    if (parts.isEmpty) return 'Not set';
    return parts.join(' ');
  }

  String _normalizeGender(String? raw) {
    if (raw == null || raw.isEmpty) return 'Not set';
    final r = raw.toLowerCase();
    if (r.startsWith('m')) return 'Male';
    if (r.startsWith('f')) return 'Female';
    if (r.startsWith('o') || r.contains('non')) return 'Other';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _formatAddressFromMap(Map<String, dynamic> addr) {
    final b = _clean(addr['building']) ?? '';
    final a = _clean(addr['area']) ?? '';
    final l = _clean(addr['landmark']) ?? '';
    final c = _clean(addr['city']) ?? '';
    final s = _clean(addr['state']) ?? '';
    final p = _clean(addr['pincode']) ?? '';
    final parts = <String>[
      if (b.isNotEmpty) b,
      if (a.isNotEmpty) a,
      if (l.isNotEmpty) l,
      if (c.isNotEmpty) c,
      if (s.isNotEmpty) s,
      if (p.isNotEmpty) ' - $p',
    ];
    final joined = parts.join(', ').replaceAll(',  -', ' -').trim();
    return joined.isEmpty ? 'Not set' : joined;
  }

  String _extractAddress(Map<String, dynamic> data) {
    // Direct string
    final addressField = data['address'];
    if (addressField is String && addressField.trim().isNotEmpty) {
      return addressField.trim();
    }
    // Direct map
    if (addressField is Map<String, dynamic>) {
      return _formatAddressFromMap(addressField);
    }
    // deliveryAddress.address map
    final deliveryAddress = data['deliveryAddress'];
    if (deliveryAddress is Map<String, dynamic>) {
      final innerAddr = deliveryAddress['address'];
      if (innerAddr is Map<String, dynamic>) {
        return _formatAddressFromMap(innerAddr);
      }
      if (innerAddr is String && innerAddr.trim().isNotEmpty) {
        return innerAddr.trim();
      }
    }
    return 'Not set';
  }

  void _handleMenuSelection(String value) {
    if (value == 'logout') {
      _confirmLogout();
    } else if (value == 'delete') {
      _confirmDeleteAccount();
    }
  }

  Future<void> _showAnimatedDialog({
    required Widget icon,
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) async {
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation =
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        final fadeAnimation =
            CurvedAnimation(parent: animation, curve: Curves.easeIn);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ValueListenableBuilder<bool>(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDark, child) {
                return AlertDialog(
                  backgroundColor:
                      isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(height: 16),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[700],
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'Stay With Us',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onConfirm();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: confirmColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                confirmText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    const orange = Color(0xFFBB694A);
    _showAnimatedDialog(
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.waving_hand_rounded, color: orange, size: 32),
      ),
      title: 'Leaving so soon?',
      content:
          'We\'ll miss you while you\'re gone! Come back soon for more updates and new collections. 🌟',
      confirmText: 'Logout',
      confirmColor: Colors.redAccent,
      onConfirm: _performLogout,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    _showAnimatedDialog(
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.heart_broken_rounded,
            color: Colors.redAccent, size: 32),
      ),
      title: "We're sorry to see you go!",
      content:
          'Deleting your account is permanent. We\'d love to keep you with us! Are you absolutely sure?',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      onConfirm: _performDeleteAccount,
    );
  }

  Future<void> _performLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFBB694A))),
    );

    try {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _performDeleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFBB694A))),
    );

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        String message = 'Failed to delete account.';
        if (e.code == 'requires-recent-login') {
          message =
              'For security, please logout and login again to delete your account.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unknown error occurred.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _launchPrivacyPortal() async {
    final Uri url = Uri.parse('https://beinn-privacy-portal.lovable.app/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch privacy portal')),
        );
      }
    }
  }

  // Navigation Methods

  void _navigateToAddresses() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProfileAddressesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const EditProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFFBB694A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToAboutUs() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AboutUsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PrivacyPolicyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToShippingReturns() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ShippingReturnsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToRefundPolicy() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RefundPolicyScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToTermsConditions() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TermsConditionsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToFAQs() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FAQsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

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
                    // Minimal AppBar Row (no bottom divider line)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      color: isDark
                          ? Colors.black
                          : const Color.fromARGB(255, 250, 249, 245),
                      child: Row(
                        children: [
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: orange,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Spacer(),
                          // UPDATED: Enhanced 3 dots menu
                          Theme(
                            data: Theme.of(context).copyWith(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              popupMenuTheme: PopupMenuThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: isDark
                                    ? const Color(0xFF2C2C2E)
                                    : Colors.white,
                                elevation: 8,
                                textStyle: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            child: PopupMenuButton<String>(
                              onSelected: _handleMenuSelection,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  size: 20,
                                ),
                              ),
                              offset: const Offset(0, 45),
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'logout',
                                    padding: EdgeInsets.zero,
                                    height: 48,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.05)
                                            : Colors.grey
                                                .withValues(alpha: 0.05),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: orange.withValues(
                                                  alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.logout_rounded,
                                                color: orange,
                                                size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    padding: EdgeInsets.zero,
                                    height: 48,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.08),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.delete_forever_rounded,
                                                color: Colors.redAccent,
                                                size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Delete Account',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BODY
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: orange, strokeWidth: 2.4),
                            )
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionTitle(
                                      text: 'Profile Information'),
                                  const SizedBox(height: 10),
                                  _CardSection(
                                    children: [
                                      _InfoItem(
                                        icon: Icons.badge_outlined,
                                        label: 'Name',
                                        value: _fullName.isNotEmpty
                                            ? _fullName
                                            : 'Not set',
                                      ),
                                      _IndentDivider(),
                                      _InfoItem(
                                        icon: Icons.email_outlined,
                                        label: 'Email',
                                        value: _email.isNotEmpty
                                            ? _email
                                            : 'Not set',
                                      ),
                                      _IndentDivider(),
                                      _InfoItem(
                                        icon: Icons.phone_outlined,
                                        label: 'Mobile',
                                        value: _mobile.isNotEmpty
                                            ? _mobile
                                            : 'Not set',
                                      ),
                                      _IndentDivider(),
                                      _InfoItem(
                                        icon: Icons.wc,
                                        label: 'Gender',
                                        value: _gender.isNotEmpty
                                            ? _gender
                                            : 'Not set',
                                      ),
                                      _IndentDivider(),
                                      _InfoItem(
                                        icon: Icons.location_on_outlined,
                                        label: 'Address',
                                        value: _address.isNotEmpty
                                            ? _address
                                            : 'Not set',
                                        multiline: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const _SectionTitle(text: 'General'),
                                  const SizedBox(height: 10),
                                  _CardSection(
                                    children: [
                                      _ActionRow(
                                        icon: Icons.edit_outlined,
                                        label: 'Edit Profile',
                                        onTap: _navigateToEditProfile,
                                      ),
                                      _DividerThin(),
                                      _ActionRow(
                                        icon: Icons.location_on_outlined,
                                        label: 'Addresses',
                                        onTap: _navigateToAddresses,
                                      ),
                                      _DividerThin(),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 4),
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 24,
                                              child: Icon(
                                                  Icons.brightness_6_outlined,
                                                  color: Color(0xFFBB694A),
                                                  size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "App's theme",
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Switch(
                                              value: isDark,
                                              onChanged: (val) {
                                                setTheme(val);
                                              },
                                              activeThumbColor:
                                                  const Color(0xFFBB694A),
                                              activeTrackColor:
                                                  const Color(0xFFBB694A)
                                                      .withValues(alpha: 0.3),
                                              inactiveThumbColor:
                                                  const Color(0xFFBB694A),
                                              inactiveTrackColor: Colors.grey[
                                                  400], // Visible in light
                                              thumbIcon: WidgetStateProperty
                                                  .resolveWith<Icon?>((states) {
                                                if (states.contains(
                                                    WidgetState.selected)) {
                                                  // Dark mode -> Moon
                                                  return const Icon(
                                                      Icons.nightlight_round,
                                                      color: Colors.black,
                                                      size: 16);
                                                }
                                                // Light mode -> Sun
                                                return const Icon(
                                                    Icons.wb_sunny,
                                                    color: Colors.black,
                                                    size: 16);
                                              }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const _SectionTitle(
                                      text: 'Support & Policies'),
                                  const SizedBox(height: 10),
                                  _CardSection(
                                    children: [
                                      _ActionRow(
                                        icon: Icons.info_outline,
                                        label: 'About Us',
                                        onTap: _navigateToAboutUs,
                                      ),
                                      _DividerThin(),
                                      _ActionRow(
                                        icon: Icons.privacy_tip_outlined,
                                        label: 'Privacy Policy',
                                        onTap: _navigateToPrivacyPolicy,
                                      ),
                                      _DividerThin(),
                                      _ActionRow(
                                        icon: Icons.local_shipping_outlined,
                                        label: 'Shipping Policy',
                                        onTap: _navigateToShippingReturns,
                                      ),
                                      _DividerThin(),
                                      _ActionRow(
                                        icon: Icons.assignment_return_outlined,
                                        label: 'Refund Policy',
                                        onTap: _navigateToRefundPolicy,
                                      ),
                                      _DividerThin(),
                                      _ActionRow(
                                        icon: Icons.article_outlined,
                                        label: 'Terms & Conditions',
                                        onTap: _navigateToTermsConditions,
                                      ),
                                      _DividerThin(),
                                      _ActionRow(
                                        icon: Icons.quiz_outlined,
                                        label: 'FAQs',
                                        onTap: _navigateToFAQs,
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 24),
                                    child: Center(
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            fontFamily: 'Outfit',
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'Want to know more about our policies? Check ',
                                            ),
                                            TextSpan(
                                              text: 'Our Policies',
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.w700,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = _launchPrivacyPortal,
                                            ),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 4),
                                                child: GestureDetector(
                                                  onTap: _launchPrivacyPortal,
                                                  child: Icon(
                                                    Icons.arrow_outward_rounded,
                                                    size: 14,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _profileSub?.cancel();
    super.dispose();
  }
}

// ---------- UI SUB-COMPONENTS ----------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          );
        });
  }
}

class _CardSection extends StatelessWidget {
  final List<Widget> children;
  const _CardSection({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                  width: 1),
            ),
            child: Column(children: children),
          );
        });
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFBB694A);

    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          final valueStyle = TextStyle(
            color: value == 'Not set'
                ? (isDark ? Colors.white70 : Colors.black54)
                : (isDark ? Colors.white : Colors.black),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.2,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: multiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Icon(icon, color: orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: .6)
                              : Colors.black.withValues(alpha: .6),
                          fontSize: 12.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: valueStyle,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class _IndentDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[850] : Colors.grey[300],
            indent: 14 + 24 + 12, // left padding + icon width + gap
            endIndent: 14,
          );
        });
  }
}

class _DividerThin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Divider(
            height: 1,
            thickness: 1,
            color: isDark ? Colors.grey[850] : Colors.grey[300],
            indent: 14,
            endIndent: 14,
          );
        });
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFBB694A);

    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: orange.withValues(alpha: .08),
              highlightColor: orange.withValues(alpha: .05),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Icon(icon, color: orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                        size: 20),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
