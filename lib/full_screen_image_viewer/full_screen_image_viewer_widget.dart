import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'full_screen_image_viewer_model.dart';
export 'full_screen_image_viewer_model.dart';

class FullScreenImageViewerWidget extends StatefulWidget {
  const FullScreenImageViewerWidget({super.key});

  static String routeName = 'FullScreenImageViewer';
  static String routePath = '/fullScreenImageViewer';

  @override
  State<FullScreenImageViewerWidget> createState() =>
      _FullScreenImageViewerWidgetState();
}

class _FullScreenImageViewerWidgetState
    extends State<FullScreenImageViewerWidget> {
  late FullScreenImageViewerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FullScreenImageViewerModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: custom_widgets.FullScreenImageViewer(
              width: double.infinity,
              height: double.infinity,
              imageUrl: FFAppState().selectedMediaFileUrl,
            ),
          ),
        ),
      ),
    );
  }
}
