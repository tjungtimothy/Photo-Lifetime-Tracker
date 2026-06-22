// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    this.width,
    this.height,
    this.userEmail, // Pass user email from signup screen to show here
  });

  final double? width;
  final double? height;
  final String? userEmail;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isChecking = false;
  Timer? _authTimer;

  @override
  void initState() {
    super.initState();

    // Auto-check session listener every 3 seconds in case app stays in background
    _authTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkUserVerified();
    });
  }

  Future<void> _checkUserVerified() async {
    // Refresh session to see if user has verified from email link
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
      _authTimer?.cancel();
      // If session becomes valid via deep linking, redirect immediately to home
      context.goNamed('home_screen');
    }
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium Dark Theme Colors matching Photo Tracker Design
    const bgColor = Color(0xFF070B10);
    const cardColor = Color(0xFF121820);
    const blueAccent = Color(0xFF4EA1FF);
    const textWhite = Color(0xFFF4F7FA);
    const textSecondary = Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SizedBox(
        width: widget.width ?? MediaQuery.of(context).size.width,
        height: widget.height ?? MediaQuery.of(context).size.height,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // 1. Animated/Glowing Email Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blueAccent.withOpacity(0.1),
                    border: Border.all(
                        color: blueAccent.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    color: blueAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Heading Texts
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    color: textWhite,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  "We've sent a verification link to:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),

                // User's Email Display
                Text(
                  widget.userEmail ?? 'your email address',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: blueAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Informational Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1C2430)),
                  ),
                  child: Text(
                    "Please click the confirmation link inside the email. Once clicked, the app will automatically log you in and take you to your dashboard.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textWhite.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),

                const Spacer(),

                // 4. Loading indicator waiting for deep-link activation
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(blueAccent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Waiting for verification...',
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.7),
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. Back to Login Button (Just in case)
                TextButton(
                  onPressed: () {
                    context.goNamed('login_screen');
                  },
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: textSecondary.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
