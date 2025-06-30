# Draggable Widget Causes Unnecessary Rebuilds of All Draggable Widgets in Widget Tree

## Summary
When using multiple `Draggable` widgets in a widget tree, starting or ending a drag operation on any single `Draggable` causes all other `Draggable` widgets to rebuild unnecessarily, even when they have independent state management.

## Expected Behavior
Only the specific `Draggable` widget being interacted with should rebuild. Other `Draggable` widgets with separate state should remain unaffected.

## Actual Behavior
All `Draggable` widgets in the widget tree rebuild when any single `Draggable` starts or ends a drag operation.

## Impact
- Performance degradation with multiple draggable elements (tested with 3+ widgets)
- Unnecessary computation and rendering cycles
- Poor user experience in apps with many draggable components
- Defeats the purpose of individual state management architectures

## Reproduction Steps
1. Create multiple `Draggable` widgets with individual state management (e.g., using Riverpod family providers)
2. Add print statements in the build methods to track rebuilds
3. Start dragging any single `Draggable` widget
4. Observe that all `Draggable` widgets print their build statements

## Minimal Reproduction Code
```dart
class DraggableWidget extends ConsumerWidget {
  final String id;
  
  const DraggableWidget({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(individualStateProvider(id));
    
    print("Building draggable widget: $id"); // This prints for ALL widgets when dragging ANY widget
    
    return Positioned(
      left: notifier.position.dx,
      top: notifier.position.dy,
      child: Draggable<String>(
        data: id,
        feedback: Container(width: 100, height: 100, color: Colors.blue),
        child: Container(width: 100, height: 100, color: Colors.red),
      ),
    );
  }
}
```

## Root Cause Analysis
The issue appears to be related to Flutter's drag overlay system. When `Draggable` creates/removes overlay widgets during drag start/end, it triggers widget tree rebuilds that cascade to other `Draggable` widgets.

## Environment
- Flutter version: [Your Flutter version]
- Dart version: [Your Dart version]
- Platform: [Your platform]

## Workaround
Replace `Draggable` with `GestureDetector` and manual position tracking:

```dart
GestureDetector(
  onPanUpdate: (details) {
    // Manual position updates - no unnecessary rebuilds
    ref.read(stateProvider(id).notifier).updatePosition(details.globalPosition);
  },
  child: Container(...)
)
```

This workaround eliminates the rebuild issue but requires manual implementation of drag functionality.

## Request
Please investigate and fix the unnecessary rebuilds in the `Draggable` widget's drag lifecycle management.