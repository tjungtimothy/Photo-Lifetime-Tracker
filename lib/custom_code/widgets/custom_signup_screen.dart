// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/auth/supabase_auth/auth_util.dart';
import '/custom_code/widgets/index.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────
const Color _kAccent = Color(0xFF3E82FC);
const Color _kBg = Color(0xFF181C1E);
const Color _kCardBg1 = Color(0x252C304D);
const Color _kCardBg2 = Color(0x1A1F2166);
const Color _kBorder = Color(0xFF384246);
const Color _kLabel = Color(0xFF7E7E7E);
const Color _kDivider = Color(0x4C605F5F);

class CustomSignupScreen extends StatefulWidget {
  const CustomSignupScreen({
    super.key,
    this.width,
    this.height,
    this.onSignupSuccess,
    this.onGoToLogin,
  });

  final double? width;
  final double? height;
  final Future<void> Function()? onSignupSuccess;
  final Future<void> Function()? onGoToLogin;

  @override
  State<CustomSignupScreen> createState() => _CustomSignupScreenState();
}

class _CustomSignupScreenState extends State<CustomSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Focus nodes
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPassFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _zipFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _termsAccepted = false;
  bool _isLoading = false;

  // Profile image bytes
  XFile? _pickedImage;
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _phoneCtrl.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPassFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _zipFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // IMAGE PICKER
  // ─────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) {
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  // ─────────────────────────────────────────────
  // VALIDATION HELPERS
  // ─────────────────────────────────────────────
  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailReg = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailReg.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v))
      return 'Must contain at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v))
      return 'Must contain at least one number';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  String? _validateZip(String? v) {
    if (v == null || v.trim().isEmpty) return 'Zip code is required';
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(v.trim()))
      return 'Enter a valid zip code';
    return null;
  }

  // ─── FIX: Phone stored as int8 in DB → parse to int ───
  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digitsOnly = v.trim().replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7) return 'Enter a valid phone number';
    return null;
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MAIN SIGNUP LOGIC
  // ─────────────────────────────────────────────

  Future<void> _handleSignup() async {
    // 1. Form Validation Check
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showSnack('Please fill in all required fields correctly.');
      return;
    }
    if (!_termsAccepted) {
      _showSnack('Please accept the Terms of Service to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ═════════════════════════════════════════════════════════════════════════
      // STEP 1: SUPABASE AUTH USER CREATE KAREIN (ORIGINAL WITH EMAIL TRIGGER)
      // ═════════════════════════════════════════════════════════════════════════
      // Yeh method perfect email confirmation bhejega aur dashboard redirect rules follow karega
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        emailRedirectTo: 'photolifetimetracker://photolifetimetracker.com/',
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        _showSnack('Account creation failed. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      final userId = authUser.id; // Unique UUID for the user

      // STEP 2: PROFILE IMAGE UPLOAD (IF SELECTED)
      String? profileImageUrl;
      if (_pickedImage != null && _imageBytes != null) {
        profileImageUrl = await _uploadProfileImage(userId);
      }

      // Safe phone format conversion (digits only for int8 support in DB)
      final phoneDigits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      final phoneInt =
          phoneDigits.isNotEmpty ? int.tryParse(phoneDigits) : null;

      // ═════════════════════════════════════════════════════════════════════════
      // STEP 3: DATA IMMEDIATELY STORE KAREIN (USING UPSERT TO PREVENT 23505 ERROR)
      // ═════════════════════════════════════════════════════════════════════════
      // 'upsert' se signup screen ka saara data abhi isi waqt save ho jayega.
      // Agar background trigger ne row bana di thi, to yeh use sahi data se fill/update kar dega.
      await SupaFlow.client.from('Users').upsert({
        'id': userId,
        'email': _emailCtrl.text.trim(),
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'zip_code': _zipCtrl.text.trim(),
        'phone': phoneInt,
        'profile_img_url': profileImageUrl,
      });

      // ═════════════════════════════════════════════════════════════════════════
      // STEP 4: REDIRECT TO EMAIL VERIFICATION SCREEN
      // ═════════════════════════════════════════════════════════════════════════
      _showSnack('Verification email sent! Please check your inbox 📧',
          isError: false);
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // User ko automatic Verification UI par le jayein jahan wo wait karega
        context.goNamed(
          'EmailVerificationScreen',
          extra: <String, dynamic>{
            'userEmail': _emailCtrl.text.trim(),
          },
        );
      }
    } on AuthException catch (e) {
      _showSnack(_parseAuthError(e.message));
    } on PostgrestException catch (e) {
      debugPrint('Supabase DB Upsert Error: ${e.message} | Code: ${e.code}');
      _showSnack('Database error: ${e.message}');
    } catch (e) {
      _showSnack('Something went wrong: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Future<void> _handleSignup() async {
  //   // FIX: Manually trigger validation and check result
  //   final isValid = _formKey.currentState?.validate() ?? false;
  //   if (!isValid) {
  //     _showSnack('Please fill in all required fields correctly.');
  //     return;
  //   }
  //   if (!_termsAccepted) {
  //     _showSnack('Please accept the Terms of Service to continue');
  //     return;
  //   }

  //   setState(() => _isLoading = true);

  //   try {
  //     // Step 1: Create auth user
  //     final authResponse = await Supabase.instance.client.auth.signUp(
  //       email: _emailCtrl.text.trim(),
  //       password: _passwordCtrl.text,
  //       // options: const SignUpOptions(
  //       //   redirectTo: 'photolifetimetracker://photolifetimetracker.com',
  //       // ),
  //     );

  //     final authUser = authResponse.user;
  //     if (authUser == null) {
  //       _showSnack('Account creation failed. Please try again.');
  //       setState(() => _isLoading = false);
  //       return;
  //     }

  //     final userId = authUser.id;

  //     // Step 2: Upload profile image if selected
  //     String? profileImageUrl;
  //     if (_pickedImage != null && _imageBytes != null) {
  //       profileImageUrl = await _uploadProfileImage(userId);
  //     }

  //     // FIX: Phone is int8 in DB → convert digits only to int
  //     final phoneDigits = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
  //     final phoneInt =
  //         phoneDigits.isNotEmpty ? int.tryParse(phoneDigits) : null;

  //     // Step 3: Insert into Users table
  //     // FIX: Fields exactly match your DB columns:
  //     //   id, email, first_name, last_name, city, state, zip_code, phone (int8), profile_img_url
  //     //   NOTE: 'street' column does NOT exist in your DB — removed it
  //     await SupaFlow.client.from('Users').insert({
  //       'id': userId, // uuid — matches auth user id
  //       'email': _emailCtrl.text.trim(), // text
  //       'first_name':
  //           _firstNameCtrl.text.trim(), // text — FIX: was mapped wrong before
  //       'last_name': _lastNameCtrl.text.trim(), // text
  //       'city': _cityCtrl.text.trim(), // text
  //       'state': _stateCtrl.text.trim(), // text
  //       'zip_code': _zipCtrl.text.trim(), // text
  //       'phone': phoneInt, // int8 — FIX: now properly converted
  //       'profile_img_url': profileImageUrl, // text (nullable)
  //     });

  //     _showSnack('Account created successfully! Welcome 🎉', isError: false);
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     if (widget.onSignupSuccess != null) {
  //       await widget.onSignupSuccess!();
  //     }

  //     if (mounted) {
  //       context.pushNamed('home_screen');
  //     }
  //   } on AuthException catch (e) {
  //     _showSnack(_parseAuthError(e.message));
  //   } on PostgrestException catch (e) {
  //     // FIX: Catch Supabase DB errors separately for better debugging
  //     debugPrint('Supabase DB insert error: ${e.message} | code: ${e.code}');
  //     _showSnack('Database error: ${e.message}');
  //   } catch (e) {
  //     _showSnack('Something went wrong: ${e.toString()}');
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }

  Future<String?> _uploadProfileImage(String userId) async {
    try {
      final ext = _pickedImage!.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final storagePath = '$userId/profile_images/profile.$ext';

      await Supabase.instance.client.storage.from('user_data').uploadBinary(
            storagePath,
            _imageBytes!,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      return Supabase.instance.client.storage
          .from('user_data')
          .getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Profile image upload error: $e');
      return null;
    }
  }

  String _parseAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('user already exists')) {
      return 'An account with this email already exists.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildFormCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Create an Account',
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Fill in your details to get started',
          style: GoogleFonts.inter(color: _kLabel, fontSize: 13),
        ),
        const SizedBox(height: 14),
        _buildDivider(),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child:
              Text('✦', style: TextStyle(color: Colors.white.withOpacity(0.2))),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kCardBg1, _kCardBg2],
          stops: [0.3, 0.4],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider, width: 0.96),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        // FIX: Changed to disabled — prevents premature red errors on first load
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileImagePicker(),
            const SizedBox(height: 20),
            _sectionLabel('Personal Information'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _firstNameCtrl,
                    focusNode: _firstNameFocus,
                    nextFocus: _lastNameFocus,
                    label: 'First Name',
                    hint: 'John',
                    validator: (v) => _validateRequired(v, 'First Name'),
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _lastNameCtrl,
                    focusNode: _lastNameFocus,
                    nextFocus: _emailFocus,
                    label: 'Last Name',
                    hint: 'Doe',
                    validator: (v) => _validateRequired(v, 'Last Name'),
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              nextFocus: _phoneFocus,
              label: 'Email Address',
              hint: 'john@example.com',
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 14),

            // FIX: Simple phone field — phone stored as int8 in DB
            // Digits only, no country code package needed
            _buildField(
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              nextFocus: _cityFocus,
              label: 'Phone Number',
              hint: '2125550100',
              validator: _validatePhone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 20),

            _sectionLabel('Address'),
            const SizedBox(height: 12),
            // FIX: Removed street field — 'street' column does NOT exist in your Users table
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _cityCtrl,
                    focusNode: _cityFocus,
                    nextFocus: _stateFocus,
                    label: 'City',
                    hint: 'New York',
                    validator: (v) => _validateRequired(v, 'City'),
                    prefixIcon: Icons.location_city_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    controller: _stateCtrl,
                    focusNode: _stateFocus,
                    nextFocus: _zipFocus,
                    label: 'State',
                    hint: 'NY',
                    validator: (v) => _validateRequired(v, 'State'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    controller: _zipCtrl,
                    focusNode: _zipFocus,
                    nextFocus: _passwordFocus,
                    label: 'Zip',
                    hint: '10001',
                    validator: _validateZip,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionLabel('Security'),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              nextFocus: _confirmPassFocus,
              label: 'Password',
              hint: '••••••••••••',
              isVisible: _passwordVisible,
              onToggleVisibility: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _confirmPassCtrl,
              focusNode: _confirmPassFocus,
              label: 'Confirm Password',
              hint: '••••••••••••',
              isVisible: _confirmVisible,
              onToggleVisibility: () =>
                  setState(() => _confirmVisible = !_confirmVisible),
              validator: _validateConfirmPassword,
              isLast: true,
            ),
            const SizedBox(height: 20),
            _buildTermsRow(),
            const SizedBox(height: 20),
            _buildSubmitButton(),
            const SizedBox(height: 14),
            _buildSignInRow(),
            const SizedBox(height: 14),
            _buildDivider(),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Or sign in with',
                style: GoogleFonts.inter(color: _kLabel, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: _imageBytes != null
                      ? _kAccent
                      : Colors.white.withOpacity(0.15),
                  width: 2,
                ),
                image: _imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                    : null,
              ),
              child: _imageBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Colors.white.withOpacity(0.4), size: 26),
                        const SizedBox(height: 4),
                        Text('Photo',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 10)),
                      ],
                    )
                  : null,
            ),
            if (_imageBytes != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBg, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    bool isLast = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          focusNode.unfocus();
        }
      },
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      cursorColor: _kAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: _kLabel, fontSize: 12),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.2), fontSize: 12),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _kLabel, size: 18)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: _kBg,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kBorder, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kAccent, width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        errorStyle: GoogleFonts.inter(
            color: Colors.redAccent, fontSize: 10, height: 1.2),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    bool isLast = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !isVisible,
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          focusNode.unfocus();
        }
      },
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      cursorColor: _kAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: _kLabel, fontSize: 12),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.2), fontSize: 12),
        prefixIcon:
            const Icon(Icons.lock_outline_rounded, color: _kLabel, size: 18),
        suffixIcon: GestureDetector(
          onTap: onToggleVisibility,
          child: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _kLabel,
            size: 18,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: _kBg,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kBorder, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kAccent, width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(8),
        ),
        errorStyle: GoogleFonts.inter(
            color: Colors.redAccent, fontSize: 10, height: 1.2),
      ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            activeColor: _kAccent,
            checkColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7), fontSize: 12),
              children: [
                const TextSpan(text: 'I agree to the '),
                WidgetSpan(
                  child: Text(
                    'Terms of Service',
                    style: GoogleFonts.poppins(
                      color: _kAccent,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: _kAccent,
                    ),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  child: Text(
                    'Privacy Policy',
                    style: GoogleFonts.poppins(
                      color: _kAccent,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: _kAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSignup,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : [const Color(0xFF3E82FC), const Color(0xFF254D96)],
            stops: const [0, 0.9],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _isLoading ? Colors.transparent : _kAccent),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  'CREATE ACCOUNT',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEDEDED),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignInRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: GoogleFonts.inter(color: _kLabel, fontSize: 12),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            if (widget.onGoToLogin != null) {
              widget.onGoToLogin!();
            }
            context.pushNamed('login_screen');
          },
          child: Text(
            'Sign in here',
            style: GoogleFonts.inter(
                color: _kAccent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
              color: _kAccent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
