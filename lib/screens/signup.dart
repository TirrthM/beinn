import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:email_validator/email_validator.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _isEmailValid = false;
  bool _isMobileValid = false;
  bool _passwordsMatch = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validatePasswordMatch);
    _emailController.addListener(_validateEmail);
    _mobileController.addListener(_validateMobile);
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
    _validatePasswordMatch();
  }

  void _validatePasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid = EmailValidator.validate(_emailController.text);
    });
  }

  void _validateMobile() {
    setState(() {
      _isMobileValid = _mobileController.text.length == 10 &&
          RegExp(r'^[0-9]+$').hasMatch(_mobileController.text);
    });
  }

  bool get _isFormValid {
    return _isEmailValid &&
        _hasMinLength &&
        _hasUppercase &&
        _hasLowercase &&
        _hasNumber &&
        _hasSpecialChar &&
        _passwordsMatch &&
        _isMobileValid;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_isFormValid) {
      _showSnackBar('Please fill all the fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting signup process...');
      print('Email: ${_emailController.text.trim()}');
      print('Mobile: +91${_mobileController.text}');

      // Create user with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('User created successfully: ${userCredential.user!.uid}');

      // Store user data in Firestore (all info except confirm password)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'mobile': '+91${_mobileController.text}',
        'createdAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'userType': 'customer',
        'signUpMethod': 'email',
        'profileComplete': false,
      });

      print('User data stored in Firestore successfully');

      // Send email verification
      await userCredential.user!.sendEmailVerification();
      print('Verification email sent');

      _showSuccessDialog();

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage = 'An error occurred during signup.';

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled. Please contact support.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Firebase Auth Error: ${e.message}';
      }
      _showErrorDialog(errorMessage);
    } on FirebaseException catch (e) {
      print('FirebaseException: ${e.code} - ${e.message}');
      String errorMessage = 'Database error occurred.';

      switch (e.code) {
        case 'permission-denied':
          errorMessage = 'Permission denied. Please check Firestore rules.';
          break;
        case 'unavailable':
          errorMessage = 'Service temporarily unavailable. Please try again.';
          break;
        default:
          errorMessage = 'Firestore Error: ${e.message}';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      print('General error: $e');
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Google sign-up...');

      // Sign out from previous sessions to ensure clean signup
      await _googleSignIn.signOut();
      await _auth.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign-up cancelled by user');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Google user signed in: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('Firebase authentication successful: ${userCredential.user!.uid}');

      // Check if user already exists in Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        // Store new user data
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isEmailVerified': true,
          'userType': 'customer',
          'signUpMethod': 'google',
          'profileComplete': false,
        });
        print('New Google user data stored');
      } else {
        print('Existing Google user signed in');
      }

      _showSuccessDialog();

    } on FirebaseAuthException catch (e) {
      print('Google FirebaseAuthException: ${e.code} - ${e.message}');
      String errorMessage = 'Google sign-up failed.';

      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid Google credentials. Please try again.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google sign-in is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this credential.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-verification-code':
          errorMessage = 'Invalid verification code.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID.';
          break;
        default:
          errorMessage = 'Google Auth Error: ${e.message}';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      print('Google sign-up general error: $e');
      String errorMessage = 'Google sign-up failed. ';

      if (e.toString().contains('PlatformException')) {
        errorMessage += 'Please check your Google configuration in Firebase Console.';
      } else if (e.toString().contains('network')) {
        errorMessage += 'Please check your internet connection.';
      } else {
        errorMessage += 'Please try again later.';
      }

      _showErrorDialog(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400]),
            SizedBox(width: 8),
            Text(
              'Error',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFD2691E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[400]),
            SizedBox(width: 8),
            Text(
              'Success!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Account created successfully! Please check your email for verification.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text(
              'Continue to Login',
              style: TextStyle(
                color: Color(0xFFD2691E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? Colors.green[600] : Colors.red[400],
            size: 14,
          ),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isValid ? Colors.green[600] : Colors.red[400],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),

                // Header Icon with Beinn branding
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFD2691E).withOpacity(0.1),
                        Color(0xFFD2691E).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: Color(0xFFD2691E).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFD2691E).withOpacity(0.2),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 50,
                        color: Color(0xFFD2691E),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'BEINN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD2691E),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Title
                Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Sign up to get started with Beinn!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[400],
                  ),
                ),

                SizedBox(height: 28),

                // Email Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey[500]
                      ),
                      suffixIcon: _emailController.text.isNotEmpty
                          ? Icon(
                        _isEmailValid ? Icons.check_circle : Icons.error,
                        color: _isEmailValid ? Color(0xFFD2691E) : Colors.red[400],
                        size: 20,
                      )
                          : null,
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ),

                SizedBox(height: 14),

                // Mobile Number Field
                Row(
                  children: [
                    // Country Code
                    Container(
                      width: 75,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.grey[800]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🇮🇳', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 3),
                            Text(
                                '+91',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Colors.white,
                                )
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: 10),

                    // Mobile Number Input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey[800]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: Colors.grey[500]
                            ),
                            suffixIcon: _mobileController.text.isNotEmpty
                                ? Icon(
                              _isMobileValid ? Icons.check_circle : Icons.error,
                              color: _isMobileValid ? Color(0xFFD2691E) : Colors.red[400],
                              size: 20,
                            )
                                : null,
                            hintText: 'Mobile Number',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 14),

                // Password Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500]
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      hintText: 'Password',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ),

                SizedBox(height: 14),

                // Confirm Password Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500]
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_confirmPasswordController.text.isNotEmpty)
                            Icon(
                              _passwordsMatch ? Icons.check_circle : Icons.error,
                              color: _passwordsMatch ? Color(0xFFD2691E) : Colors.red[400],
                              size: 20,
                            ),
                          IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ],
                      ),
                      hintText: 'Confirm Password',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Validation Requirements
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildValidationItem('Min 8 Characters', _hasMinLength),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildValidationItem('Min 1 Number', _hasNumber),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildValidationItem('Min 1 Uppercase', _hasUppercase),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildValidationItem('Min 1 Special', _hasSpecialChar),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      _buildValidationItem('Min 1 Lowercase letter', _hasLowercase),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Sign Up Button (Changed to OutlinedButton that becomes filled when valid)
                Container(
                  width: double.infinity,
                  height: 56,
                  child: _isFormValid
                      ? ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD2691E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: Color(0xFFD2691E).withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                      : OutlinedButton(
                    onPressed: _signUp,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFD2691E), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Color(0xFFD2691E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD2691E),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[700], thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[700], thickness: 1)),
                  ],
                ),

                SizedBox(height: 20),

                // Google Sign Up Button
                Container(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _signUpWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[700]!, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.grey[900],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.g_mobiledata,
                            color: Colors.red[600],
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Sign Up with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFFD2691E),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}
