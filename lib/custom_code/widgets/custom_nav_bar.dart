// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'index.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({
    super.key,
    this.width,
    this.height,
    required this.currentIndex,
    this.onTap,
  });

  final double? width;
  final double? height;
  final int currentIndex;
  final Future Function(int index)? onTap;

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(CustomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _selectedIndex = widget.currentIndex;
    }
  }

  Widget _buildNavIcon({
    required String assetPath,
    required double size,
    required Color tintColor,
  }) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tintColor, BlendMode.srcATop),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          if (assetPath.contains('gallery')) {
            return Icon(Icons.image, size: size, color: tintColor);
          }
          if (assetPath.contains('upload')) {
            return Icon(Icons.upload_file, size: size, color: tintColor);
          }
          if (assetPath.contains('report')) {
            return Icon(Icons.analytics, size: size, color: tintColor);
          }
          return Icon(Icons.person, size: size, color: tintColor);
        },
      ),
    );
  }

  // ✅ SIMPLE NAVIGATION - NO FANCY STUFF
  void _handleNavigation(int index) {
    // Agar same index hai to skip karo
    if (index == _selectedIndex) {
      return;
    }

    // Update UI immediately
    setState(() {
      _selectedIndex = index;
    });

    // Call parent callback if provided
    if (widget.onTap != null) {
      widget.onTap!(index);
      return; // Parent handle karega navigation
    }

    // Direct navigation based on index
    switch (index) {
      case 0:
        context.goNamed('home_screen');
        break;
      case 1:
        context.goNamed('upload_screen');
        break;
      case 2:
        context.goNamed('report_screen');
        break;
      case 3:
        context.goNamed('profile_screen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': 'assets/images/gallery.png', 'label': 'GALLERY'},
      {'icon': 'assets/images/upload.png', 'label': 'UPLOAD'},
      {'icon': 'assets/images/reports.png', 'label': 'REPORTS'},
      {'icon': 'assets/images/profile.png', 'label': 'PROFILE'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 72,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFFFFFFF),
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isSelected = _selectedIndex == index;
                final color = isSelected
                    ? const Color(0xFF379DF0)
                    : const Color(0xFFAAAAAA).withOpacity(1);
                final double iconSize = isSelected ? 28 : 26;

                return GestureDetector(
                  onTap: () => _handleNavigation(index),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavIcon(
                          assetPath: items[index]['icon'] as String,
                          size: iconSize,
                          tintColor: color,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          items[index]['label'] as String,
                          style: TextStyle(
                            color: color,
                            fontSize: 9,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
