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

## Drag Feedback Scaling Solution
### Problem Solved: Draggable feedback widget scaling with InteractiveViewer zoom
- **Issue**: Feedback widget not scaling with canvas zoom level
- **Solution**: Use `Builder` widget in `feedback` to capture scale at drag time
- **Implementation**: `ref.read(canvasScaleProvider)` in Builder function prevents rebuilds
- **Performance**: No rebuilds on zoom, scale only read when dragging starts

### Canvas Scale Provider
- `canvasScaleProvider` updated by TransformationController listener in OrgCanvas  
- Blocks don't watch this provider (no rebuilds)
- Scale captured only during drag operations via `ref.read()`

## Database Architecture - Real-time Firestore

### Collection Structure
```
/organizations/{orgId}/
  blocks/{blockId} - individual block documents
  emails/{emailId} - email documents with blockId reference
```

### Block Data Model
```dart
{
  id: "blockId",
  position: {x: 100, y: 200},
  name: "John Doe", 
  department: "Engineering",
  role: "Manager",
  parentId: "parentBlockId", // null if root
  childrenIds: ["child1", "child2"],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### FirestoreService Methods (`/lib/services/firestoreService.dart`)
```dart
// CRUD operations using flexible Map<String, dynamic>
static Future<void> addBlock(String orgId, Map<String, dynamic> blockData)
static Future<void> updateBlock(String orgId, String blockId, Map<String, dynamic> updates) 
static Future<void> deleteBlock(String orgId, String blockId)

// Planned: Real-time reading
static Stream<QuerySnapshot> getBlocksStream(String orgId) // For real-time updates
```

### Real-time Strategy
- **Approach**: Firestore snapshots for real-time collaboration
- **Performance**: Individual BlockNotifier architecture prevents cascade rebuilds
- **Updates**: All block operations (add, move, edit, delete) sync immediately to Firestore
- **Collaboration**: Multiple users can edit same canvas with live updates

### Email Separation
- Emails stored in separate collection to avoid document size limits
- 6000+ emails across 100-300 blocks requires separate docs
- Email documents reference blockId for efficient querying

## Future Enhancements
- Real-time snapshot integration with existing notifiers
- Block connections visualization  
- Block data editing (name, department)
- Email management UI
- Offline persistence and conflict resolution

## Commands
- `flutter analyze` - Check for issues
- `flutter run` - Run the app