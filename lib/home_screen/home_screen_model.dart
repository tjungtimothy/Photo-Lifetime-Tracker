import '/components/auth_divider_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_screen_widget.dart' show HomeScreenWidget;
import 'package:flutter/material.dart';

class HomeScreenModel extends FlutterFlowModel<HomeScreenWidget> {
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
