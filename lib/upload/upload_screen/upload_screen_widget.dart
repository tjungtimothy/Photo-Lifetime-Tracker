import '/components/common_nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'upload_screen_model.dart';
export 'upload_screen_model.dart';

class UploadScreenWidget extends StatefulWidget {
  const UploadScreenWidget({super.key});

  static String routeName = 'upload_screen';
  static String routePath = '/uploadScreen';

  @override
  State<UploadScreenWidget> createState() => _UploadScreenWidgetState();
}

class _UploadScreenWidgetState extends State<UploadScreenWidget> {
  late UploadScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UploadScreenModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: Color(0xFF181C1E),
        automaticallyImplyLeading: true,
        actions: [],
        centerTitle: true,
        elevation: 0.0,
      ),
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              child: custom_widgets.UploadScreen(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                wrapWithModel(
                  model: _model.commonNavBarModel,
                  updateCallback: () => safeSetState(() {}),
                  updateOnChange: true,
                  child: Hero(
                    tag: '',
                    transitionOnUserGestures: true,
                    child: Material(
                      color: Colors.transparent,
                      child: CommonNavBarWidget(
                        navIndex: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
