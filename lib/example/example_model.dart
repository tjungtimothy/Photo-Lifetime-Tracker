import '/components/common_nav_bar_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'example_widget.dart' show ExampleWidget;
import 'package:flutter/material.dart';

class ExampleModel extends FlutterFlowModel<ExampleWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for CommonNavBar component.
  late CommonNavBarModel commonNavBarModel;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {
    commonNavBarModel = createModel(context, () => CommonNavBarModel());
  }

  @override
  void dispose() {
    commonNavBarModel.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
