import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_addresses.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _listenUserProfile();
  }

  void _setupAnimations() {
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _slideController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slide = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _listenUserProfile() {
    final user = _auth.currentUser;
    setState(() {
      _email = user?.email ?? '';
      _loading = true;
    });

    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    _profileSub = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      final data = doc.data() ?? {};

      final first = _clean(data['firstName']) ?? _clean(data['firstname']);
      final last = _clean(data['lastName']) ?? _clean(data['lastname']);
      final combined = _combineName(first, last);

      final emailFromDb =
          _clean(data['email']) ?? _clean(data['mail']) ?? _email;

      final mobile =
          _clean(data['mobile']) ??
              _clean(data['phone']) ??
              _clean(data['phoneNumber']) ??
              '';

      final gender = _normalizeGender(_clean(data['gender']));

      // Address can be:
      // - String in 'address'
      // - Map in 'address' with building/area/landmark/city/state/pincode
      // - Nested under 'deliveryAddress.address'
      final address = _extractAddress(data);

      setState(() {
        _fullName = combined;
        _email = emailFromDb;
        _mobile = mobile ?? '';
        _gender = gender;
        _address = address;
        _loading = false;
      });
    }, onError: (e) {
      debugPrint('Profile listen error: $e');
      setState(() => _loading = false);
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

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: Color(0xFFD2691E))),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _navigateToAddresses() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ProfileAddressesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
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
        pageBuilder: (context, animation, secondaryAnimation) => const EditProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
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
          backgroundColor: Color(0xFFD2691E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFD2691E);

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Column(
              children: [
                // Minimal AppBar Row (no bottom divider line)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  color: Colors.black,
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
                      GestureDetector(
                        onTap: _handleLogout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.red[600]!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red[600]!.withOpacity(0.25), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, color: Colors.red[500], size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.red[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // BODY
                Expanded(
                  child: _loading
                      ? const Center(
                    child: CircularProgressIndicator(color: orange, strokeWidth: 2.4),
                  )
                      : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(text: 'Profile Information'),
                        const SizedBox(height: 10),
                        _CardSection(
                          children: [
                            _InfoItem(
                              icon: Icons.badge_outlined,
                              label: 'Name',
                              value: _fullName.isNotEmpty ? _fullName : 'Not set',
                            ),
                            _IndentDivider(),
                            _InfoItem(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: _email.isNotEmpty ? _email : 'Not set',
                            ),
                            _IndentDivider(),
                            _InfoItem(
                              icon: Icons.phone_outlined,
                              label: 'Mobile',
                              value: _mobile.isNotEmpty ? _mobile : 'Not set',
                            ),
                            _IndentDivider(),
                            _InfoItem(
                              icon: Icons.wc,
                              label: 'Gender',
                              value: _gender.isNotEmpty ? _gender : 'Not set',
                            ),
                            _IndentDivider(),
                            _InfoItem(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: _address.isNotEmpty ? _address : 'Not set',
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
                          ],
                        ),

                        const SizedBox(height: 24),
                        const _SectionTitle(text: 'Support & Policies'),
                        const SizedBox(height: 10),
                        _CardSection(
                          children: [
                            _ActionRow(
                              icon: Icons.info_outline,
                              label: 'About Us',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('About Us - Coming Soon!'),
                                    backgroundColor: orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _DividerThin(),
                            _ActionRow(
                              icon: Icons.help_outline,
                              label: 'Help & Support',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Help & Support - Coming Soon!'),
                                    backgroundColor: orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _DividerThin(),
                            _ActionRow(
                              icon: Icons.description_outlined,
                              label: 'License & Agreement',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('License & Agreement - Coming Soon!'),
                                    backgroundColor: orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _DividerThin(),
                            _ActionRow(
                              icon: Icons.quiz_outlined,
                              label: 'FAQs',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('FAQs - Coming Soon!'),
                                    backgroundColor: orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 100), // space for bottom nav
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
  const _SectionTitle({Key? key, required this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final List<Widget> children;
  const _CardSection({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[850]!, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _InfoItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFD2691E);

    final valueStyle = TextStyle(
      color: value == 'Not set' ? Colors.white70 : Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
                    color: Colors.white.withOpacity(.6),
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
  }
}

class _IndentDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[850],
      indent: 14 + 24 + 12, // left padding + icon width + gap
      endIndent: 14,
    );
  }
}

class _DividerThin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey[850],
      indent: 14,
      endIndent: 14,
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFD2691E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: orange.withOpacity(.08),
        highlightColor: orange.withOpacity(.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
