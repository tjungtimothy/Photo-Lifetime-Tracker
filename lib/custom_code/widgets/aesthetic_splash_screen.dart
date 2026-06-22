// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/custom_code/widgets/index.dart';

import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class AestheticSplashScreen extends StatefulWidget {
  const AestheticSplashScreen({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<AestheticSplashScreen> createState() => _AestheticSplashScreenState();
}

class _AestheticSplashScreenState extends State<AestheticSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _contentController;

  late Animation<double> _logoFade;
  late Animation<double> _tagFade;
  late Animation<Offset> _logoSlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(
        0,
        .5,
        curve: Curves.easeOut,
      ),
    );

    _tagFade = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(
        .4,
        1,
        curve: Curves.easeOut,
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, .25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      const Duration(milliseconds: 1200),
      () {
        if (mounted) {
          _contentController.forward();
        }
      },
    );

    Timer(
      const Duration(milliseconds: 4800),
      _handleNavigation,
    );
  }

  Future<void> _handleNavigation() async {
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      context.goNamed('home_screen');
    } else {
      context.goNamed('login_screen');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF070B10);
    const white = Color(0xFFF4F7FA);
    const secondary = Color(0xFF9CA3AF);
    const gold = Color(0xFFC9A55C);

    final images = [
      'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?q=80&w=1200',
      'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=1200',
      'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?q=80&w=1200',
      'https://images.unsplash.com/photo-1493863641943-9b68992a8d07?q=80&w=1200',
      'https://images.unsplash.com/photo-1452587925148-ce544e77e70d?q=80&w=1200',
      'https://images.unsplash.com/photo-1516724562728-afc824a36e84?q=80&w=1200',
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SizedBox(
        width: widget.width ?? MediaQuery.of(context).size.width,
        height: widget.height ?? MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, child) {
                  final offset =
                      math.sin(_bgController.value * math.pi * 2) * 45;

                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Transform.rotate(
                      angle: -.16,
                      child: Transform.scale(
                        scale: 1.35,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(14),
                          itemCount: 18,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: .72,
                          ),
                          itemBuilder: (context, index) {
                            final image = images[index % images.length];

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    color: Colors.black.withOpacity(.55),
                                  ),
                                  BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 2,
                                      sigmaY: 2,
                                    ),
                                    child: Container(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.7),
                      bgColor.withOpacity(.85),
                      bgColor
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(),
                      FadeTransition(
                        opacity: _logoFade,
                        child: SlideTransition(
                          position: _logoSlide,
                          child: Column(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(.05),
                                  border: Border.all(
                                    color: gold.withOpacity(.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withOpacity(.15),
                                      blurRadius: 30,
                                    )
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Image.network(
                                  'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/photo-tracker-ui8id5/assets/ygb234fhugbq/logo1.png',
                                  fit: BoxFit.contain,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Icon(
                                      Icons.photo_camera,
                                      color: Colors.white,
                                      size: 50,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                "THE",
                                style: TextStyle(
                                  color: white.withOpacity(.9),
                                  fontSize: 13,
                                  letterSpacing: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'CREATIVE ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'EDGE',
                                      style: TextStyle(
                                        color: gold,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "STUDIO",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  letterSpacing: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _tagFade,
                        child: Column(
                          children: [
                            Text(
                              'PROMOTING EXCELLENCE IN PHOTOGRAPHY',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: white.withOpacity(.9),
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Beta Testing Version',
                              style: TextStyle(
                                color: gold,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation(gold),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Creative Edge Studio • MVP Build',
                          style: TextStyle(
                            color: secondary.withOpacity(.5),
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
