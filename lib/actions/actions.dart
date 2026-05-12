import '/actions/actions.dart' as action_blocks;
import 'package:flutter/material.dart';

Future back(BuildContext context) async {
  await action_blocks.back(context);
}
