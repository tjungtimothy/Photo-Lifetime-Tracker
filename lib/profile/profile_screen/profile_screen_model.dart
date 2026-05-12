import '/components/common_nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'profile_screen_widget.dart' show ProfileScreenWidget;
import 'package:flutter/material.dart';

class ProfileScreenModel extends FlutterFlowModel<ProfileScreenWidget> {
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
