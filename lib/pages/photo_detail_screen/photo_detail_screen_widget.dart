import '/backend/supabase/supabase.dart';
import '/components/auth_divider_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
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

    return FutureBuilder<List<ContestEntriesRow>>(
      future: ContestEntriesTable().queryRows(
        queryFn: (q) => q.eqOrNull(
          'media_id',
          FFAppState().selectedMediaId,
        ),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<ContestEntriesRow> photoDetailScreenContestEntriesRowList =
            snapshot.data!;

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
                  Stack(
                    children: [
                      custom_widgets.NetworkImageWidget(
                        width: double.infinity,
                        height: 280.0,
                        imageUrl: FFAppState().selectedMediaFileUrl,
                        borderRadius: 5.0,
                      ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              5.0, 10.0, 5.0, 5.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 5.0, 0.0),
                                child: Container(
                                  width: 30.0,
                                  height: 30.0,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFA4A4A4),
                                        Color(0xFF252525)
                                      ],
                                      stops: [0.0, 1.0],
                                      begin: AlignmentDirectional(0.0, -1.0),
                                      end: AlignmentDirectional(0, 1.0),
                                    ),
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                  child: InkWell(
                                    splashColor: Colors.transparent,
                                    focusColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: () async {
                                      context.pushNamed(
                                          FullScreenImageViewerWidget
                                              .routeName);
                                    },
                                    child: Icon(
                                      Icons.remove_red_eye_outlined,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 18.0,
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  context.safePop();
                                },
                                child: Container(
                                  width: 30.0,
                                  height: 30.0,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFA4A4A4),
                                        Color(0xFF252525)
                                      ],
                                      stops: [0.0, 1.0],
                                      begin: AlignmentDirectional(0.0, -1.0),
                                      end: AlignmentDirectional(0, 1.0),
                                    ),
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                  child: Icon(
                                    Icons.close_sharp,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 18.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(10.0, 10.0, 10.0, 10.0),
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
      },
    );
  }
}
