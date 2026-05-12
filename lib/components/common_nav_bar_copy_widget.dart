import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'common_nav_bar_copy_model.dart';
export 'common_nav_bar_copy_model.dart';

class CommonNavBarCopyWidget extends StatefulWidget {
  const CommonNavBarCopyWidget({
    super.key,
    int? navIndex,
  }) : this.navIndex = navIndex ?? 0;

  final int navIndex;

  @override
  State<CommonNavBarCopyWidget> createState() => _CommonNavBarCopyWidgetState();
}

class _CommonNavBarCopyWidgetState extends State<CommonNavBarCopyWidget> {
  late CommonNavBarCopyModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CommonNavBarCopyModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80.0,
      child: custom_widgets.CustomNavBar(
        width: double.infinity,
        height: 80.0,
        currentIndex: widget.navIndex,
        onTap: (index) async {
          if (index == 0 ? true : false) {
            context.pushNamed(ExampleWidget.routeName);
          } else {
            if (index == 1) {
              context.pushNamed(UploadScreenWidget.routeName);
            } else {
              if (index == 2) {
                context.pushNamed(ReportScreenWidget.routeName);
              } else {
                if (index == 3) {
                  context.pushNamed(ProfileScreenWidget.routeName);
                }
              }
            }
          }
        },
      ),
    );
  }
}
