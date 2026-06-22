// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:ui';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({
    super.key,
    this.width,
    this.height,
    required this.imageUrl,
  });

  final double? width;
  final double? height;
  final String imageUrl;

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _controller = TransformationController();
  double _currentScale = 1.0;
  bool _isFullCoverMode = false;

  // Strict Zoom Limits
  final double _maxScaleLimit = 4.0;
  final double _minScaleLimit = 1.0;

  /// Helper function to calculate centered matrix based on target scale
  Matrix4 _calculateCenteredMatrix(double targetScale) {
    final size = MediaQuery.of(context).size;
    final double xOffset = (size.width - (size.width * targetScale)) / 2;
    final double yOffset = (size.height - (size.height * targetScale)) / 2;

    return Matrix4.identity()
      ..translate(xOffset, yOffset)
      ..scale(targetScale);
  }

  // Double tap to smart zoom toggle (Always centered)
  void _handleDoubleTap() {
    setState(() {
      if (_currentScale > 1.0) {
        _currentScale = 1.0;
        _isFullCoverMode = false;
        _controller.value = Matrix4.identity();
      } else {
        _currentScale = 2.5;
        _isFullCoverMode = false;
        _controller.value = _calculateCenteredMatrix(_currentScale);
      }
    });
  }

  /// FIX: Zoom In with strict max limit and absolute centering logic
  void _zoomIn() {
    if (_currentScale >= _maxScaleLimit) return; // Prevent zooming past 4x

    setState(() {
      _currentScale += 0.5;
      if (_currentScale > _maxScaleLimit) _currentScale = _maxScaleLimit;
      _isFullCoverMode = false;

      // Update matrix with viewport center calculation
      _controller.value = _calculateCenteredMatrix(_currentScale);
    });
  }

  /// FIX: Zoom Out with strict min limit and absolute centering logic
  void _zoomOut() {
    if (_currentScale <= _minScaleLimit) return; // Prevent zooming below 1x

    setState(() {
      _currentScale -= 0.5;
      if (_currentScale < _minScaleLimit) _currentScale = _minScaleLimit;
      _isFullCoverMode = false;

      if (_currentScale == 1.0) {
        _controller.value = Matrix4.identity(); // Reset flat
      } else {
        _controller.value = _calculateCenteredMatrix(_currentScale);
      }
    });
  }

  /// FIX: Centered Full Cover Matrix Transformation
  void _toggleFullCover() {
    setState(() {
      _isFullCoverMode = !_isFullCoverMode;

      if (_isFullCoverMode) {
        _currentScale =
            2.2; // Optimized scale to perfectly fill modern phone screens
        _controller.value = _calculateCenteredMatrix(_currentScale);
      } else {
        _currentScale = 1.0;
        _controller.value = Matrix4.identity();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0A0C0E), // Immersive deep dark background
      body: Stack(
        children: [
          /// ── IMMERSIVE INTERACTIVE IMAGE VIEWER ──
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: Center(
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: _minScaleLimit,
                  maxScale: _maxScaleLimit,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: EdgeInsets.zero,
                  // Sync pinch-to-zoom scales with our state trackers
                  onInteractionUpdate: (details) {
                    _currentScale = _controller.value.getMaxScaleOnAxis();
                  },
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit
                        .contain, // Stays contain so layout parameters remain consistent
                    width: widget.width ?? double.infinity,
                    height: widget.height ?? double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF379DF0),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              color: Colors.white.withOpacity(0.2), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          /// ── PREMIUM TOP CLOSE BUTTON ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _premiumCircleBtn(
              icon: Icons.close_rounded,
              onTap: () => context.pop(),
            ),
          ),

          /// ── PREMIUM FLOATING CONTROLS DOCK (BOTTOM) ──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0x66111315),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// ZOOM OUT
                    _premiumCircleBtn(
                      icon: Icons.remove_rounded,
                      onTap: _zoomOut,
                    ),
                    const SizedBox(width: 14),

                    /// SMART FULL COVER MODE TOGGLE
                    _premiumCircleBtn(
                      icon: _isFullCoverMode
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      onTap: _toggleFullCover,
                    ),
                    const SizedBox(width: 14),

                    /// ZOOM IN
                    _premiumCircleBtn(
                      icon: Icons.add_rounded,
                      onTap: _zoomIn,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable Premium Gradient Translucent Button Style
  Widget _premiumCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: const LinearGradient(
            colors: [
              Color(0xE5A4A4A4), // Translucent silver gray (#A4A4A4E5)
              Color(0x99252525), // Dark charcoal mask (#25252599)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white.withOpacity(0.95),
            size: 20,
          ),
        ),
      ),
    );
  }
}
