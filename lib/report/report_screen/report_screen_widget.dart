import '/components/common_nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'report_screen_model.dart';
export 'report_screen_model.dart';

class ReportScreenWidget extends StatefulWidget {
  const ReportScreenWidget({super.key});

  static String routeName = 'report_screen';
  static String routePath = '/reportScreen';

  @override
  State<ReportScreenWidget> createState() => _ReportScreenWidgetState();
}

class _ReportScreenWidgetState extends State<ReportScreenWidget> {
  late ReportScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReportScreenModel());
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
                child: custom_widgets.ReportsScreen(
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
                          navIndex: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
