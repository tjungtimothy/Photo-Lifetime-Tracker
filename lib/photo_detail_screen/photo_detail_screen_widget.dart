import '/components/auth_divider_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'photo_detail_screen_model.dart';
export 'photo_detail_screen_model.dart';

class PhotoDetailScreenWidget extends StatefulWidget {
  const PhotoDetailScreenWidget({super.key});

  static String routeName = 'photoDetail_screen';
  static String routePath = '/photoDetailScreen';

  @override
  State<PhotoDetailScreenWidget> createState() =>
      _PhotoDetailScreenWidgetState();
}

class _PhotoDetailScreenWidgetState extends State<PhotoDetailScreenWidget> {
  late PhotoDetailScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PhotoDetailScreenModel());
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
        appBar: AppBar(
          backgroundColor: Color(0xFF181C1E),
          automaticallyImplyLeading: true,
          actions: [],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              custom_widgets.NetworkImageWidget(
                width: double.infinity,
                height: 280.0,
                imageUrl: FFAppState().selectedMediaFileUrl,
                borderRadius: 5.0,
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 10.0),
                child: wrapWithModel(
                  model: _model.authDividerModel,
                  updateCallback: () => safeSetState(() {}),
                  child: AuthDividerWidget(),
                ),
              ),
              Expanded(
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 400.0,
                      child: custom_widgets.MediaDetailTabs(
                        width: double.infinity,
                        height: 400.0,
                        mediaId: FFAppState().selectedMediaId,
                        averageScore: FFAppState().selectedMediaAvgScore,
                        highestScore: FFAppState().selectedMediaHighScore,
                        entryNumber: FFAppState().selectedMediaEntry,
                        metadataJson: FFAppState().selectedMediaMetadata,
                        processingDataJson:
                            FFAppState().selectedMediaProcessing,
                        captureDate: FFAppState().selectedMediaDate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
