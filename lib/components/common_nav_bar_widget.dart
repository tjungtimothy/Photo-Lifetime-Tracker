import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'package:flutter/material.dart';
import 'common_nav_bar_model.dart';
export 'common_nav_bar_model.dart';

class CommonNavBarWidget extends StatefulWidget {
  const CommonNavBarWidget({
    super.key,
    int? navIndex,
  }) : this.navIndex = navIndex ?? 0;

  final int navIndex;

  @override
  State<CommonNavBarWidget> createState() => _CommonNavBarWidgetState();
}

class _CommonNavBarWidgetState extends State<CommonNavBarWidget> {
  late CommonNavBarModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CommonNavBarModel());
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
