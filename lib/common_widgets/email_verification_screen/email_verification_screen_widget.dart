import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'email_verification_screen_model.dart';
export 'email_verification_screen_model.dart';

class EmailVerificationScreenWidget extends StatefulWidget {
  const EmailVerificationScreenWidget({super.key});

  static String routeName = 'EmailVerificationScreen';
  static String routePath = '/emailVerificationScreen';

  @override
  State<EmailVerificationScreenWidget> createState() =>
      _EmailVerificationScreenWidgetState();
}

class _EmailVerificationScreenWidgetState
    extends State<EmailVerificationScreenWidget> {
  late EmailVerificationScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailVerificationScreenModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(1.0, 0.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: custom_widgets.EmailVerificationScreen(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
