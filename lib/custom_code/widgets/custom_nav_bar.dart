// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class CustomNavBar extends StatefulWidget {
  const CustomNavBar({
    super.key,
    this.width,
    this.height,
    required this.currentIndex,
    required this.onTap,
  });

  final double? width;
  final double? height;
  final int currentIndex;
  final Future Function(int index) onTap;

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'GALLERY'},
      {'icon': Icons.upload_rounded, 'label': 'UPLOAD'},
      {'icon': Icons.bar_chart_rounded, 'label': 'REPORTS'},
      {'icon': Icons.person_rounded, 'label': 'PROFILE'},
    ];

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = widget.currentIndex == index;
          final color = isSelected
              ? FlutterFlowTheme.of(context).primary
              : Colors.white.withOpacity(0.35);

          return GestureDetector(
            onTap: () => widget.onTap(index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  items[index]['icon'] as IconData,
                  size: 22,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  items[index]['label'] as String,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
