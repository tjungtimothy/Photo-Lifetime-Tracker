// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/auth/supabase_auth/auth_util.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────
const Color _kAccent = Color(0xFF3E82FC);
const Color _kBg = Color(0xFF0D1117);
const Color _kCardBg = Color(0xFF1E2328);
const Color _kBorder = Color(0xFF384246);
const Color _kLabel = Color(0xFF7E7E7E);
const Color _kDivider = Color(0x4C605F5F);
const Color _kDeepBlue1 = Color(0xFF0A1628);
const Color _kDeepBlue2 = Color(0xFF0D1F3C);
const Color _kDeepBlue3 = Color(0xFF112244);

class CustomLoginScreen extends StatefulWidget {
  const CustomLoginScreen({
    super.key,
    this.width,
    this.height,
    this.onLoginSuccess,
    this.onGoToSignup,
    this.onForgotPassword,
  });

  final double? width;
  final double? height;
  final Future<void> Function()? onLoginSuccess;
  final Future<void> Function()? onGoToSignup;
  final Future<void> Function()? onForgotPassword;

  @override
  State<CustomLoginScreen> createState() => _CustomLoginScreenState();
}

class _CustomLoginScreenState extends State<CustomLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _passwordVisible = false;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final reg = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!reg.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ─────────────────────────────────────────────
  // SNACKBAR
  // ─────────────────────────────────────────────
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
  // LOGIN
  // ─────────────────────────────────────────────
  Future<void> _handleLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (response.user == null) {
        _showSnack('Login failed. Please check your credentials.');
        return;
      }
      _showSnack('Welcome back! 👋', isError: false);
      await Future.delayed(const Duration(milliseconds: 400));
      if (widget.onLoginSuccess != null) await widget.onLoginSuccess!();
      if (mounted) context.pushNamed('home_screen');
    } on AuthException catch (e) {
      _showSnack(_parseAuthError(e.message));
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────
  // FORGOT PASSWORD
  // ─────────────────────────────────────────────
  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Enter your email first, then tap Forget Password');
      return;
    }
    final reg = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!reg.hasMatch(email)) {
      _showSnack('Enter a valid email address first');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showSnack('Password reset email sent! Check your inbox.',
          isError: false);
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Could not send reset email. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (widget.onForgotPassword != null) await widget.onForgotPassword!();
  }

  String _parseAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('email not confirmed')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lower.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return message;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _kBg,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          // ── Premium deep-blue gradient background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kDeepBlue1,
                _kDeepBlue2,
                _kDeepBlue3,
                Color(0xFF0A0F1E),
              ],
              stops: [0.0, 0.35, 0.70, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),

                            // ══════════════════════════════════════
                            // 1. TOP HEADER — Logo + Sponsor text
                            // ══════════════════════════════════════
                            _buildTopHeader(),

                            const SizedBox(height: 28),

                            // ══════════════════════════════════════
                            // 2. LOGIN CARD
                            // ══════════════════════════════════════
                            _buildCard(),

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ══════════════════════════════════════
                // 4. FOOTER SPONSOR SECTION (pinned bottom)
                // ══════════════════════════════════════
                _buildSponsorFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TOP HEADER — Creative Edge Studio Logo + Sponsored by text
  // ══════════════════════════════════════════════════════════════
  Widget _buildTopHeader() {
    return Column(
      children: [
        // ── Logo placeholder
        // TODO: Replace with your actual asset or network image:
        //   Image.asset('assets/images/creative_edge_logo.png', height: 90)
        //   Image.network('https://your-logo-url.com/logo.png', height: 90)
        Container(
          height: 90,
          width: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _kAccent.withOpacity(0.25),
                _kDeepBlue2.withOpacity(0.6),
              ],
            ),
            border: Border.all(
              color: _kAccent.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.photo_camera_rounded,
              // ── REPLACE THIS ICON with your actual logo widget
              color: _kAccent.withOpacity(0.85),
              size: 38,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── App name
        Text(
          'Creative Edge Studio',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 6),

        // ── Sponsored by line
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 1,
              color: _kAccent.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Text(
              'Sponsored by The Image Critique Show',
              style: GoogleFonts.inter(
                color: _kAccent.withOpacity(0.75),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 1,
              color: _kAccent.withOpacity(0.4),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // LOGIN CARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kDivider, width: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _kAccent.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Welcome text
            Text(
              'Welcome back',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.85),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Post your latest image on our community board',
              style: GoogleFonts.inter(
                color: _kLabel,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 28),

            // ── Email field
            _buildField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              nextFocus: _passwordFocus,
              label: 'Email',
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),

            // ── Password field
            _buildPasswordField(),
            const SizedBox(height: 10),

            // ── Forget Password
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _handleForgotPassword,
                child: Text(
                  'Forget Password?',
                  style: GoogleFonts.inter(
                    color: _kAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── LOGIN Button
            _buildLoginButton(),
            const SizedBox(height: 16),

            // ── Divider

            // ══════════════════════════════════════
            // 3. JOIN NOW Button
            // ══════════════════════════════════════
            _buildJoinNowButton(),
            const SizedBox(height: 6),

            Center(
              child: Text(
                "Not Yet A Member? JOIN NOW",
                style: GoogleFonts.inter(
                  color: _kLabel,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text field
  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
        labelStyle: GoogleFonts.inter(color: _kLabel, fontSize: 13),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.2), fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        filled: true,
        fillColor: _kBg,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kBorder, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kAccent, width: 1.4),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        errorStyle: GoogleFonts.inter(
            color: Colors.redAccent, fontSize: 10, height: 1.2),
      ),
    );
  }

  // ── Password field
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      focusNode: _passwordFocus,
      obscureText: !_passwordVisible,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        _passwordFocus.unfocus();
        _handleLogin();
      },
      validator: _validatePassword,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      cursorColor: _kAccent,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: GoogleFonts.inter(color: _kLabel, fontSize: 13),
        hintText: '••••••••',
        hintStyle: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.2), fontSize: 12),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _passwordVisible = !_passwordVisible),
          child: Icon(
            _passwordVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: _kLabel,
            size: 18,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        filled: true,
        fillColor: _kBg,
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kBorder, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kAccent, width: 1.4),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.8)),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        errorStyle: GoogleFonts.inter(
            color: Colors.redAccent, fontSize: 10, height: 1.2),
      ),
    );
  }

  // ── LOGIN button
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [Colors.grey.shade700, Colors.grey.shade800]
                : [const Color(0xFF4A8FFF), const Color(0xFF1A4FC4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
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
                  'LOGIN',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════
  // 3. JOIN NOW button
  // ══════════════════════════════════════
  Widget _buildJoinNowButton() {
    return GestureDetector(
      onTap: () async {
        if (widget.onGoToSignup != null) await widget.onGoToSignup!();
        if (mounted) context.pushNamed('signup_screen');
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _kAccent, width: 1.6),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'JOIN NOW',
                style: GoogleFonts.poppins(
                  color: _kAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── OAuth placeholder button
  Widget _buildOAuthPlaceholder(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Divider
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.10))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('✦',
              style: TextStyle(color: Colors.white.withOpacity(0.15))),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.10))),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 4. FOOTER SPONSOR SECTION
  // ══════════════════════════════════════════════════════════════
  Widget _buildSponsorFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        border: Border(
          top: BorderSide(color: _kBorder.withOpacity(0.4), width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PROUDLY SPONSORED BY',
            style: GoogleFonts.inter(
              color: _kLabel.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── SPONSOR LOGO 1 PLACEHOLDER
              // TODO: Replace with:
              //   Image.asset('assets/images/sponsor1_logo.png', height: 32)
              //   Image.network('https://sponsor1.com/logo.png', height: 32)
              _buildSponsorLogo(
                icon: Icons.camera_alt_rounded,
                label: 'Sponsor 1',
                // Replace label with actual sponsor name
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: 1,
                height: 28,
                color: _kBorder.withOpacity(0.5),
              ),

              // ── SPONSOR LOGO 2 PLACEHOLDER
              // TODO: Replace with:
              //   Image.asset('assets/images/sponsor2_logo.png', height: 32)
              //   Image.network('https://sponsor2.com/logo.png', height: 32)
              _buildSponsorLogo(
                icon: Icons.photo_library_rounded,
                label: 'Sponsor 2',
                // Replace label with actual sponsor name
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorLogo({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _kLabel.withOpacity(0.6), size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: _kLabel.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
