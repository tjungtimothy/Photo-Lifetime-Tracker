import '/backend/supabase/supabase.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
            body: SafeArea(
              top: true,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: custom_widgets.PhotoDetailScreen(
                  width: double.infinity,
                  height: double.infinity,
                  mediaId: FFAppState().selectedMediaId,
                  imageUrl: FFAppState().selectedMediaFileUrl,
                  title: FFAppState().selectedMediaTitle,
                  averageScore: FFAppState().selectedMediaAvgScore,
                  highestScore: FFAppState().selectedMediaHighScore,
                  metadataJson: FFAppState().selectedMediaMetadata,
                  processingDataJson: FFAppState().selectedMediaProcessing,
                  entryNumber: FFAppState().selectedMediaEntry,
                  captureDate: FFAppState().selectedMediaDate,
                  entriesJson: '',
                  onBack: () async {
                    context.pushNamed(HomeScreenWidget.routeName);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
