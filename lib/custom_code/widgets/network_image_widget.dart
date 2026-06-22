// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    super.key,
    this.width,
    this.height,
    required this.imageUrl,
    this.borderRadius = 0.0,
  });

  final double? width;
  final double? height;
  final String imageUrl;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
          ? Image.network(
              imageUrl,
              width: width ?? double.infinity,
              height: height ?? double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1D21),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.white.withOpacity(0.2),
                    size: 40,
                  ),
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: const Color(0xFF1A1D21),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                );
              },
            )
          : Container(
              color: const Color(0xFF1A1D21),
              child: Center(
                child: Icon(
                  Icons.image_rounded,
                  color: Colors.white.withOpacity(0.2),
                  size: 40,
                ),
              ),
            ),
    );
  }
}
