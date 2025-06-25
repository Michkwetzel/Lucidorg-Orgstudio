# Canvas Block System - Performance Optimization

## Overview
Canvas app with drag-and-drop blocks optimized for 100+ blocks with individual state management and minimal rebuilds.

## Architecture

### Core Components

#### 1. BlockNotifier (`/lib/notifiers/general/blockNotifier.dart`)
- Individual ChangeNotifier per block
- Manages: position, name, department
- Auto-disposed when block deleted

#### 2. CanvasNotifier (`/lib/notifiers/general/canvasNotifier.dart`)
- Manages block IDs and connections
- Handles block addition/deletion
- Connection management for future block linking

#### 3. OrgBlock (`/lib/widgets/components/general/orgBlock.dart`)
- ConsumerWidget that watches individual BlockNotifier
- Draggable with position updates
- Delete functionality with confirmation

#### 4. OrgCanvas (`/lib/widgets/pages/app/orgCanvas.dart`)
- DragTarget for block creation and movement
- Uses ValueKey for widget stability
- Watches blockListProvider for minimal rebuilds

### Providers (`/lib/config/provider.dart`)

```dart
// Main canvas state management
final canvasProvider = StateNotifierProvider<CanvasNotifier, CanvasState>

// Individual block state (auto-disposed)
final blockNotifierProvider = ChangeNotifierProvider.family.autoDispose<BlockNotifier, String>

// Performance optimization providers
final blockListProvider = StateProvider<Set<String>>  // Derived from canvas
final connectionListProvider = StateProvider<List<Connection>>  // Derived from canvas
```

## Performance Optimizations

### 1. Individual Block State
- Each block has its own ChangeNotifier
- Moving one block only rebuilds that block
- No cascading rebuilds to other blocks

### 2. Widget Stability
- ValueKey(blockId) prevents unnecessary widget recreation
- Flutter's widget diffing preserves existing widgets

### 3. Separated Concerns
- Block list separate from connections
- Canvas operations don't affect individual block rendering
- Auto-disposal prevents memory leaks

### 4. Minimal Rebuilds
- Adding block: Only Stack rebuilds, existing widgets preserved
- Moving block: Only that specific block rebuilds  
- Deleting block: Block auto-disposed, connections cleaned up

## Usage Patterns

### Adding Blocks
1. Drag from ToolBarHud to Canvas
2. Canvas creates new block ID
3. BlockNotifier created automatically via provider.family
4. Position initialized via postFrameCallback

### Moving Blocks
1. Drag existing block
2. Only that block's position updates
3. Other blocks unaffected

### Deleting Blocks
1. Confirmation dialog on delete button
2. Canvas removes block ID and related connections
3. BlockNotifier auto-disposed when no longer watched

## Future Enhancements
- Block connections visualization
- Block data editing (name, department)
- Persistence layer integration
- Canvas save/load functionality

## Commands
- `flutter analyze` - Check for issues
- `flutter run` - Run the app