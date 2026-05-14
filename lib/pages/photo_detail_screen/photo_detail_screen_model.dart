import '/components/auth_divider_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'photo_detail_screen_widget.dart' show PhotoDetailScreenWidget;
import 'package:flutter/material.dart';

class PhotoDetailScreenModel extends FlutterFlowModel<PhotoDetailScreenWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for authDivider component.
  late AuthDividerModel authDividerModel;

  @override
  void initState(BuildContext context) {
    authDividerModel = createModel(context, () => AuthDividerModel());
  }

  @override
  void dispose() {
    authDividerModel.dispose();
  }
}
