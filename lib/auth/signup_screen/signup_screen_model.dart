import '/components/auth_divider_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'signup_screen_widget.dart' show SignupScreenWidget;
import 'package:flutter/material.dart';

class SignupScreenModel extends FlutterFlowModel<SignupScreenWidget> {
  ///  Local state fields for this page.

  bool checkValue = false;

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();
  // Model for authDivider component.
  late AuthDividerModel authDividerModel1;
  // State field(s) for namefield widget.
  FocusNode? namefieldFocusNode;
  TextEditingController? namefieldTextController;
  String? Function(BuildContext, String?)? namefieldTextControllerValidator;
  String? _namefieldTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Field is required';
    }

    if (!RegExp(kTextValidatorUsernameRegex).hasMatch(val)) {
      return 'Must start with a letter and can only contain letters, digits and - or _.';
    }
    return null;
  }

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
      return 'Please provide atleast 8 digit s password';
    }

    return null;
  }

  // State field(s) for confirmpassfield widget.
  FocusNode? confirmpassfieldFocusNode;
  TextEditingController? confirmpassfieldTextController;
  late bool confirmpassfieldVisibility;
  String? Function(BuildContext, String?)?
      confirmpassfieldTextControllerValidator;
  String? _confirmpassfieldTextControllerValidator(
      BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Confirm Password is required';
    }

    return null;
  }

  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  // Model for authDivider component.
  late AuthDividerModel authDividerModel2;

  @override
  void initState(BuildContext context) {
    authDividerModel1 = createModel(context, () => AuthDividerModel());
    namefieldTextControllerValidator = _namefieldTextControllerValidator;
    emailfieldTextControllerValidator = _emailfieldTextControllerValidator;
    passwordfieldVisibility = false;
    passwordfieldTextControllerValidator =
        _passwordfieldTextControllerValidator;
    confirmpassfieldVisibility = false;
    confirmpassfieldTextControllerValidator =
        _confirmpassfieldTextControllerValidator;
    authDividerModel2 = createModel(context, () => AuthDividerModel());
  }

  @override
  void dispose() {
    authDividerModel1.dispose();
    namefieldFocusNode?.dispose();
    namefieldTextController?.dispose();

    emailfieldFocusNode?.dispose();
    emailfieldTextController?.dispose();

    passwordfieldFocusNode?.dispose();
    passwordfieldTextController?.dispose();

    confirmpassfieldFocusNode?.dispose();
    confirmpassfieldTextController?.dispose();

    authDividerModel2.dispose();
  }
}
