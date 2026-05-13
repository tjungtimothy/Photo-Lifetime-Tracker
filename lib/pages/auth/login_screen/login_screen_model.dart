import '/components/auth_divider_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'login_screen_widget.dart' show LoginScreenWidget;
import 'package:flutter/material.dart';

class LoginScreenModel extends FlutterFlowModel<LoginScreenWidget> {
  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for authDivider component.
  late AuthDividerModel authDividerModel1;
  // State field(s) for emailfield widget.
  FocusNode? emailfieldFocusNode;
  TextEditingController? emailfieldTextController;
  String? Function(BuildContext, String?)? emailfieldTextControllerValidator;
  String? _emailfieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Field is required';
    }

    if (!RegExp(kTextValidatorEmailRegex).hasMatch(val)) {
      return 'Has to be a valid email address.';
    }
    return null;
  }

  // State field(s) for passwordfield widget.
  FocusNode? passwordfieldFocusNode;
  TextEditingController? passwordfieldTextController;
  late bool passwordfieldVisibility;
  String? Function(BuildContext, String?)? passwordfieldTextControllerValidator;
  String? _passwordfieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Field is required';
    }

    if (val.length < 8) {
      return 'Please provide atlease 8 digits password';
    }

    return null;
  }

  // Model for authDivider component.
  late AuthDividerModel authDividerModel2;

  @override
  void initState(BuildContext context) {
    authDividerModel1 = createModel(context, () => AuthDividerModel());
    emailfieldTextControllerValidator = _emailfieldTextControllerValidator;
    passwordfieldVisibility = false;
    passwordfieldTextControllerValidator =
        _passwordfieldTextControllerValidator;
    authDividerModel2 = createModel(context, () => AuthDividerModel());
  }

  @override
  void dispose() {
    authDividerModel1.dispose();
    emailfieldFocusNode?.dispose();
    emailfieldTextController?.dispose();

    passwordfieldFocusNode?.dispose();
    passwordfieldTextController?.dispose();

    authDividerModel2.dispose();
  }
}
