import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'searchscreen_model.dart';
export 'searchscreen_model.dart';

class SearchscreenWidget extends StatefulWidget {
  const SearchscreenWidget({super.key});

  static String routeName = 'searchscreen';
  static String routePath = '/searchscreen';

  @override
  State<SearchscreenWidget> createState() => _SearchscreenWidgetState();
}

class _SearchscreenWidgetState extends State<SearchscreenWidget> {
  late SearchscreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SearchscreenModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: custom_widgets.SearchScreen(
              width: double.infinity,
              height: double.infinity,
              onCardTap: (mediaId) async {
                context.pushNamed(PhotoDetailScreenWidget.routeName);
              },
            ),
          ),
        ),
      ),
    );
  }
}
