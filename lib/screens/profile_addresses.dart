import 'dart:async';
import '../theme_notifier.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_address.dart';

class ProfileAddressesScreen extends StatefulWidget {
  const ProfileAddressesScreen({Key? key}) : super(key: key);

  @override
  State<ProfileAddressesScreen> createState() => _ProfileAddressesScreenState();
}

class _ProfileAddressesScreenState extends State<ProfileAddressesScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animations
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _scaleController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  Map<String, dynamic>? _mainProfileAddress;
  bool _loadingMain = true;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMainProfileAddress();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scale =
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack);

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _loadMainProfileAddress() {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loadingMain = false);
      return;
    }
    _userDocSub =
        _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
      final data = doc.data();
      if (data != null && data['address'] != null) {
        final addressData = data['address'];
        Map<String, dynamic> addr = {};

        // Handle both Map<String, dynamic> and Map<dynamic, dynamic>
        if (addressData is Map) {
          addr = Map<String, dynamic>.from(addressData);
        }

        setState(() {
          _mainProfileAddress = {
            'id': 'main_profile',
            'fullName':
                '${(data['firstName'] ?? '').toString()} ${(data['lastName'] ?? '').toString()}'
                    .trim(),
            'email': (data['email'] ?? '').toString(),
            'mobile': (data['phone'] ?? '').toString().replaceFirst('+91', ''),
            'address': addr,
            'addressType': 'HOME',
            'isDefault': true,
            'isMainProfile': true,
          };
          _loadingMain = false;
        });
      } else {
        setState(() {
          _mainProfileAddress = null;
          _loadingMain = false;
        });
      }
    }, onError: (e) {
      debugPrint('Error loading main profile address: $e');
      setState(() => _loadingMain = false);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _userDocSub?.cancel();
    super.dispose();
  }

  String _formatFullAddress(Map<String, dynamic> address) {
    final building = (address['building'] ?? '').toString();
    final area = (address['area'] ?? '').toString();
    final landmarkV = (address['landmark'] ?? '').toString();
    final landmark = landmarkV.isNotEmpty ? '$landmarkV, ' : '';
    final city = (address['city'] ?? '').toString();
    final state = (address['state'] ?? '').toString();
    final pincode = (address['pincode'] ?? '').toString();
    return '$building, $area, $landmark$city, $state - $pincode'
        .replaceAll(RegExp(r', ,'), ',')
        .trim();
  }

  void _openNewAddress() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NewAddressScreen(),
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
          content: Text('Address added successfully'),
          backgroundColor: Color(0xFFBB694A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openEditAddress(Map<String, dynamic> address) async {
    final addressData = address['address'];
    Map<String, dynamic> addr = {};

    // Handle both Map<String, dynamic> and Map<dynamic, dynamic>
    if (addressData is Map) {
      addr = Map<String, dynamic>.from(addressData);
    }

    // Create a properly formatted address object for editing
    final editAddressData = {
      'id': address['id'],
      'firstName': address['fullName']?.toString().split(' ').first ?? '',
      'lastName':
          address['fullName']?.toString().split(' ').skip(1).join(' ') ?? '',
      'email': address['email']?.toString() ?? '',
      'mobile': address['mobile']?.toString() ?? '',
      'building': addr['building']?.toString() ?? '',
      'landmark': addr['landmark']?.toString() ?? '',
      'area': addr['area']?.toString() ?? '',
      'city': addr['city']?.toString() ?? '',
      'state': addr['state']?.toString() ?? '',
      'pincode': addr['pincode']?.toString() ?? '',
      'addressType': address['addressType']?.toString() ?? 'HOME',
      'isDefault': address['isDefault'] ?? false,
      'isMainProfile': address['isMainProfile'] ?? false,
    };

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NewAddressScreen(
          existingAddress: editAddressData,
          isEditing: true,
        ),
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
          content: Text('Address updated successfully'),
          backgroundColor: Color(0xFFBB694A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteAddress(Map<String, dynamic> address) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      if (address['isMainProfile'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Main profile address cannot be deleted here'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('saved_addresses')
          .doc(address['id'])
          .delete();

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted'),
          backgroundColor: Color(0xFFBB694A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting address: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openOptionsDialog(Map<String, dynamic> address) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Address Options',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curved =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return Transform.scale(
          scale: 0.96 + 0.04 * curved.value,
          child: Opacity(
            opacity: curved.value,
            child: Center(
              child: _OptionsDialog(
                onClose: () => Navigator.of(context).pop(),
                onEdit: () {
                  Navigator.of(context).pop();
                  _openEditAddress(address);
                },
                onDelete: () => _deleteAddress(address),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFBB694A);
    final user = _auth.currentUser;

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
                      // Header
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.arrow_back_ios_new,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Saved Addresses',
                                style: TextStyle(
                                  color: orange,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Expanded(
                        child: user == null
                            ? Center(
                                child: Text(
                                  'Please sign in to view addresses',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.grey[600]),
                                ),
                              )
                            : StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>>(
                                stream: _firestore
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('saved_addresses')
                                    .orderBy('createdAt', descending: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final isLoading = snapshot.connectionState ==
                                          ConnectionState.waiting ||
                                      _loadingMain;
                                  if (isLoading) {
                                    return const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: orange,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  final docs = snapshot.data?.docs ?? [];
                                  final addresses = <Map<String, dynamic>>[];
                                  if (_mainProfileAddress != null) {
                                    addresses.add(_mainProfileAddress!);
                                  }

                                  for (final d in docs) {
                                    final data = d.data();
                                    Map<String, dynamic> addressData = {};

                                    // Handle address field type casting
                                    if (data['address'] is Map) {
                                      addressData = Map<String, dynamic>.from(
                                          data['address']);
                                    }

                                    addresses.add({
                                      'id': d.id,
                                      'fullName':
                                          data['fullName']?.toString() ?? '',
                                      'email': data['email']?.toString() ?? '',
                                      'mobile':
                                          data['mobile']?.toString() ?? '',
                                      'address': addressData,
                                      'addressType':
                                          data['addressType']?.toString() ??
                                              'HOME',
                                      'isDefault': data['isDefault'] ?? false,
                                      'isMainProfile': false,
                                    });
                                  }

                                  if (addresses.isEmpty) {
                                    return SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 20),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.grey[900]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: isDark
                                                      ? Colors.grey[800]!
                                                      : Colors.grey[300]!,
                                                  width: 1),
                                              boxShadow: isDark
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.05),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: orange
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Icon(
                                                      Icons.location_off,
                                                      color: orange,
                                                      size: 18),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'No saved addresses yet',
                                                    style: TextStyle(
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.grey[600],
                                                        fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: addresses.length,
                                    itemBuilder: (context, index) {
                                      final address = addresses[index];
                                      final addr = address['address']
                                              as Map<String, dynamic>? ??
                                          {};
                                      final fullAddress =
                                          _formatFullAddress(addr);
                                      final isMain =
                                          address['isMainProfile'] == true;

                                      return _AddressCard(
                                        index: index,
                                        fullName: (address['fullName'] ?? '')
                                            .toString(),
                                        addressType:
                                            (address['addressType'] ?? 'HOME')
                                                .toString(),
                                        fullAddress: fullAddress,
                                        mobile: (address['mobile'] ?? '')
                                            .toString(),
                                        email:
                                            (address['email'] ?? '').toString(),
                                        showMenu: !isMain,
                                        onMenuTap: () =>
                                            _openOptionsDialog(address),
                                        isDark: isDark,
                                      );
                                    },
                                  );
                                },
                              ),
                      ),

                      // Bottom Add New button
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.white,
                          border: Border(
                              top: BorderSide(
                                  color: isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
                                  width: 1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _openNewAddress,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22)),
                                elevation: 3,
                                shadowColor: orange.withOpacity(0.25),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add New',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class _AddressCard extends StatelessWidget {
  final int index;
  final String fullName;
  final String addressType;
  final String fullAddress;
  final String mobile;
  final String email;
  final bool showMenu;
  final VoidCallback onMenuTap;
  final bool isDark;

  const _AddressCard({
    Key? key,
    required this.index,
    required this.fullName,
    required this.addressType,
    required this.fullAddress,
    required this.mobile,
    required this.email,
    required this.showMenu,
    required this.onMenuTap,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFBB694A);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          fullName.isNotEmpty ? fullName : 'Not set',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: orange.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: orange.withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          addressType,
                          style: const TextStyle(
                            color: orange,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fullAddress,
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (mobile.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            color: orange, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          '+91 $mobile',
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            color: orange, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (showMenu)
              GestureDetector(
                onTap: onMenuTap,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.more_vert,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionsDialog extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OptionsDialog({
    Key? key,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFBB694A);

    return ValueListenableBuilder<bool>(
        valueListenable: isDarkModeNotifier,
        builder: (context, isDark, child) {
          return Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101012) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? Colors.grey[850]! : Colors.grey[300]!,
                    width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune, color: orange, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Address options',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                          color: isDark ? Colors.grey[850] : Colors.grey[300],
                          height: 1,
                          thickness: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _DialogActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              color: orange,
                              bg: orange.withOpacity(0.12),
                              onTap: onEdit,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DialogActionButton(
                              icon: Icons.delete_outline,
                              label: 'Delete',
                              color: Colors.red,
                              bg: Colors.red.withOpacity(0.12),
                              onTap: onDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class _DialogActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _DialogActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween(begin: 0.94, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.scale(scale: t, child: child);
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
