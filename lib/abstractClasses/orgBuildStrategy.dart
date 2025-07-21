import 'package:flutter/material.dart';
import 'package:platform_v2/abstractClasses/blockBehaviourStrategy.dart';
import 'package:platform_v2/abstractClasses/blockContext.dart';
import 'package:platform_v2/config/constants.dart';

//Class encupasulating Block behaviour and appearance in OrgBuild mode
class OrgBuildStrategy extends BlockBehaviorStrategy {
  @override
  Widget getBlockDataDisplay(BlockContext context, double hitboxOffset) {
    return Positioned(
      left: hitboxOffset,
      top: hitboxOffset,
      child: Container(
        width: kBlockWidth,
        height: kBlockHeight,
        decoration: getDecoration(context),
        child: Column(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(context.blockNotifier.blockData?.name ?? ""),
            Text(context.blockNotifier.blockData?.role ?? ""),
            Text(context.blockNotifier.blockData?.department ?? ""),
          ],
        ),
      ),
    );
  }

  @override
  BoxDecoration getDecoration(BlockContext context) {
    if (context.blockNotifier.selectionMode) {
      return kboxShadowNormal.copyWith(border: Border.all(color: Colors.blue, width: 2));
    } else if (context.blockNotifier.blockData?.hasMultipleEmails ?? false) {
      return kboxShadowNormal.copyWith(border: Border.all(color: Colors.black, width: 2));
    }
    return kboxShadowNormal;
  }
}
