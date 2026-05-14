// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/actions/actions.dart' as action_blocks;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

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

  /// IMAGE FIT TOGGLE
  bool _isPortraitFit = true;

  void _zoomIn() {
    setState(() {
      _currentScale += 0.3;

      if (_currentScale > 4) {
        _currentScale = 4;
      }

      _controller.value = Matrix4.identity()..scale(_currentScale);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale -= 0.3;

      if (_currentScale < 1) {
        _currentScale = 1;
      }

      _controller.value = Matrix4.identity()..scale(_currentScale);
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
      backgroundColor: const Color(0xFF111315),
      body: SafeArea(
        child: Stack(
          children: [
            /// IMAGE VIEWER
            Center(
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1,
                maxScale: 4,
                panEnabled: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00A3FF),
                        width: 1.5,
                      ),
                    ),
                    child: Image.network(
                      widget.imageUrl,

                      /// TOGGLE FIT MODE
                      fit: _isPortraitFit ? BoxFit.contain : BoxFit.cover,

                      width: widget.width ?? double.infinity,
                      height: widget.height ?? double.infinity,

                      /// LOADING
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return Container(
                          width: double.infinity,
                          height: 500,
                          color: const Color(0xFF1A1D21),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },

                      /// ERROR
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 500,
                          color: const Color(0xFF1A1D21),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white54,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            /// CLOSE BUTTON
            Positioned(
              top: 12,
              right: 14,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7E7E7E),
                        Color(0xFF252525),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            /// CONTROLS
            Positioned(
              bottom: 28,
              right: 18,
              child: Column(
                children: [
                  /// ZOOM IN
                  _zoomButton(
                    icon: Icons.add,
                    onTap: _zoomIn,
                  ),

                  const SizedBox(height: 10),

                  /// ZOOM OUT
                  _zoomButton(
                    icon: Icons.remove,
                    onTap: _zoomOut,
                  ),

                  const SizedBox(height: 10),

                  /// PORTRAIT / LANDSCAPE TOGGLE
                  _zoomButton(
                    icon: _isPortraitFit
                        ? Icons.crop_landscape_rounded
                        : Icons.portrait_rounded,
                    onTap: () {
                      setState(() {
                        _isPortraitFit = !_isPortraitFit;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2C2F33),
              Color(0xFF1A1D21),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFF3E82FC),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
