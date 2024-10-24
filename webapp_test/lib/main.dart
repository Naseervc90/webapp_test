import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> with TickerProviderStateMixin {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// The index of the item currently being dragged.
  int? _draggedIndex;

  /// The target index where the dragged item might be dropped.
  int? _targetIndex;

  /// Animation controller for item movements.
  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _items.length,
          (index) => _buildDraggableItem(index),
        ),
      ),
    );
  }

  /// Builds a draggable item at the specified [index].
  Widget _buildDraggableItem(int index) {
    return Draggable<int>(
      data: index,
      feedback: _buildFeedback(index),
      childWhenDragging: _buildPlaceholder(),
      onDragStarted: () => _handleDragStart(index),
      onDragEnd: (details) => _handleDragEnd(),
      onDragUpdate: (details) => _handleDragUpdate(details, index),
      child: DragTarget<int>(
        onWillAccept: (data) => data != null && data != index,
        onAccept: (data) => _handleAccept(data, index),
        builder: (context, candidateData, rejectedData) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: _calculateOffset(index),
                child: child,
              );
            },
            child: widget.builder(_items[index]),
          );
        },
      ),
    );
  }

  /// Builds the feedback widget shown while dragging.
  Widget _buildFeedback(int index) {
    return Material(
      color: Colors.transparent,
      child: widget.builder(_items[index]),
    );
  }

  /// Builds a placeholder widget shown in the original position while dragging.
  Widget _buildPlaceholder() {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      height: 48,
      margin: const EdgeInsets.all(8),
    );
  }

  /// Calculates the offset for animating items during drag operations.
  Offset _calculateOffset(int index) {
    if (_draggedIndex == null || _targetIndex == null) return Offset.zero;

    final draggedItem = _draggedIndex!;
    final targetItem = _targetIndex!;

    if (index == draggedItem) {
      return Offset.zero;
    }

    if (_shouldItemMove(index, draggedItem, targetItem)) {
      final direction = targetItem > draggedItem ? 1 : -1;
      return Offset(64.0 * direction * _animationController.value, 0);
    }

    return Offset.zero;
  }

  /// Determines if an item should move based on drag operation.
  bool _shouldItemMove(int itemIndex, int draggedIndex, int targetIndex) {
    if (targetIndex > draggedIndex) {
      return itemIndex > draggedIndex && itemIndex <= targetIndex;
    } else {
      return itemIndex < draggedIndex && itemIndex >= targetIndex;
    }
  }

  /// Handles the start of a drag operation.
  void _handleDragStart(int index) {
    setState(() {
      _draggedIndex = index;
      _targetIndex = index;
    });
  }

  /// Handles updates during a drag operation.
  void _handleDragUpdate(DragUpdateDetails details, int index) {
    if (_draggedIndex == null) return;

    final box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final newTargetIndex = _calculateTargetIndex(localPosition);

    if (newTargetIndex != _targetIndex) {
      setState(() {
        _targetIndex = newTargetIndex;
      });
      _animationController.forward(from: 0.0);
    }
  }

  /// Calculates the target index based on drag position.
  int _calculateTargetIndex(Offset localPosition) {
    final itemWidth = 64.0; // Approximate width of each item
    int index = (localPosition.dx / itemWidth).floor();
    return index.clamp(0, _items.length - 1);
  }

  /// Handles the end of a drag operation.
  void _handleDragEnd() {
    _animationController.reverse().then((_) {
      setState(() {
        _draggedIndex = null;
        _targetIndex = null;
      });
    });
  }

  /// Handles the acceptance of a dragged item at a new position.
  void _handleAccept(int draggedIndex, int targetIndex) {
    setState(() {
      final item = _items.removeAt(draggedIndex);
      _items.insert(targetIndex, item);
    });
  }
}
