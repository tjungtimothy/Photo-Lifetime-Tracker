import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'auth_divider_model.dart';
export 'auth_divider_model.dart';

class AuthDividerWidget extends StatefulWidget {
  const AuthDividerWidget({super.key});

  @override
  State<AuthDividerWidget> createState() => _AuthDividerWidgetState();
}

class _AuthDividerWidgetState extends State<AuthDividerWidget> {
  late AuthDividerModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AuthDividerModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.2,
      child: Align(
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Container(
          width: double.infinity,
          height: 1.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            border: Border.all(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
