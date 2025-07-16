// import 'package:flutter/material.dart';
// import 'package:platform_v2/config/enums.dart';
// import 'package:platform_v2/notifiers/general/blockNotifier.dart';
// import 'package:platform_v2/notifiers/general/connectionsManager.dart';
// import 'package:platform_v2/notifiers/general/orgCanvasNotifier.dart';

// //Base abstract block detailing possible functions
// abstract class BaseBlockMode {
//   BlockMode get modeName;

//   onTap();
//   onDoubleTap(TapDownDetails details);
//   onPanUpdate(DragUpdateDetails details, RenderBox? canvasBox);

//   onLeftTap();
//   onRightTap();
//   onTopTap();
//   onBottomTap();

//   BoxDecoration get decoration;
//   Widget get blockDataDisplay;
// }

// class OrgBuildMode extends BaseBlockMode {
//   final BlockNotifier blockNotifier;
//   final OrgCanvasNotifier orgCanvasNotifier;
//   final ConnectionManager connectionManager;

//   OrgBuildMode(this.blockNotifier, this.orgCanvasNotifier, this.connectionManager);

//   @override
//   BlockMode get modeName => BlockMode.orgBuild;

//   @override
//   onTap() {
//     // TODO: implement onTap
//     throw UnimplementedError();
//   }
// }
