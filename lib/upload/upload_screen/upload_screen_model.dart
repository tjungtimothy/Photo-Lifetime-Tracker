import '/components/common_nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'upload_screen_widget.dart' show UploadScreenWidget;
import 'package:flutter/material.dart';

class UploadScreenModel extends FlutterFlowModel<UploadScreenWidget> {
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
