import '/common_widgets/common_nav_bar/common_nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'report_screen_widget.dart' show ReportScreenWidget;
import 'package:flutter/material.dart';

class ReportScreenModel extends FlutterFlowModel<ReportScreenWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for CommonNavBar component.
  late CommonNavBarModel commonNavBarModel;

  @override
  void initState(BuildContext context) {
    commonNavBarModel = createModel(context, () => CommonNavBarModel());
  }

  @override
  void dispose() {
    commonNavBarModel.dispose();
  }
}
