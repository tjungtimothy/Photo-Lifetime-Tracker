import '/common_widgets/common_nav_bar/common_nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_screen_widget.dart' show HomeScreenWidget;
import 'package:flutter/material.dart';

class HomeScreenModel extends FlutterFlowModel<HomeScreenWidget> {
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
