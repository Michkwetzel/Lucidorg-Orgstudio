import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/widgets/components/general/orgBlock.dart';

class CanvasNotifier extends StateNotifier<List<OrgBlock>> {
  CanvasNotifier() : super([OrgBlock(x: 100, y: 100),OrgBlock(x: 500, y: 500),OrgBlock(x: 400, y: 400)]);

  void addBlock(double x, double y) {
    state = [...state, OrgBlock(x: x, y: y)];
  }
}
