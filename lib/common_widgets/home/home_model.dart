import '/common_widgets/auth_divider/auth_divider_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_widget.dart' show HomeWidget;
import 'package:flutter/material.dart';

class HomeModel extends FlutterFlowModel<HomeWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for authDivider component.
  late AuthDividerModel authDividerModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    authDividerModel = createModel(context, () => AuthDividerModel());
  }

  @override
  void dispose() {
    authDividerModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
