import 'package:flutter/material.dart';

class DraggableResizable extends StatelessWidget {
  const DraggableResizable({
    required this.child,
    required this.rect,
    required this.onUpdate,
    required this.isSelected,
    required this.constraints,
    this.minSize = const Size(50, 50),
    this.onDelete,      // This is now effectively "Undo" or "Delete" or "Magic Wand" based on usage
    this.onLayerAction, // This is "Cycle BG" or "Order"
    this.actionIcon,
    this.deleteIcon,    // Custom icon for top-right handle
    super.key,
  });

  final Widget child;
  final Rect rect;
  final ValueChanged<Rect> onUpdate;
  final bool isSelected;
  final BoxConstraints constraints;
  final Size minSize;
  final VoidCallback? onDelete;      // Top Right action
  final VoidCallback? onLayerAction; // Bottom Left action
  final IconData? actionIcon;
  final IconData? deleteIcon;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content Area (Tap to Select)
          GestureDetector(
             onPanUpdate: isSelected ? (details) {
                 final newLeft = rect.left + details.delta.dx;
                 final newTop = rect.top + details.delta.dy;
                 onUpdate(Rect.fromLTWH(newLeft, newTop, rect.width, rect.height));
             } : null,
             child: Container(
                color: Colors.transparent, 
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                    if (isSelected)
                        IgnorePointer(
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blueAccent, width: 2),
                                ),
                            ),
                        ),
                  ],
                ),
             ),
          ),

          if (isSelected) ...[
            // 1. Move Handle (Top Left)
            Positioned(
                left: -12,
                top: -12,
                child: _buildHandle(
                    icon: Icons.open_with,
                    color: Colors.blueAccent,
                    onPanUpdate: (details) {
                         final newLeft = rect.left + details.delta.dx;
                         final newTop = rect.top + details.delta.dy;
                         onUpdate(Rect.fromLTWH(newLeft, newTop, rect.width, rect.height));
                    }
                ),
            ),

            // 2. Resize Handle (Bottom Right)
            Positioned(
              right: -12,
              bottom: -12,
              child: _buildHandle(
                  icon: Icons.open_in_full,
                  color: Colors.blueAccent,
                  onPanUpdate: (details) {
                    final newWidth = (rect.width + details.delta.dx).clamp(minSize.width, constraints.maxWidth);
                    final newHeight = (rect.height + details.delta.dy).clamp(minSize.height, constraints.maxHeight);
                    onUpdate(Rect.fromLTWH(rect.left, rect.top, newWidth, newHeight));
                  }
              ),
            ),
            
            // 3. Top Right Handle (Custom Action: Delete/Undo/MagicWand)
            if (onDelete != null)
                Positioned(
                    right: -12,
                    top: -12,
                    child: _buildButtonHandle(
                        icon: deleteIcon ?? Icons.delete, // Default to Delete
                        color: Colors.redAccent,
                        onTap: onDelete!
                    ),
                ),

            // 4. Bottom Left Handle (Custom Action: BG/Layers)
            if (onLayerAction != null)
                Positioned(
                    left: -12,
                    bottom: -12,
                    child: _buildButtonHandle(
                        icon: actionIcon ?? Icons.circle,
                        color: Colors.orangeAccent,
                        onTap: onLayerAction!
                    ),
                ),
          ]
        ],
      ),
    );
  }

  Widget _buildHandle({required IconData icon, required Color color, required GestureDragUpdateCallback onPanUpdate}) {
      return GestureDetector(
        onPanUpdate: onPanUpdate,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
  }

  Widget _buildButtonHandle({required IconData icon, required Color color, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
  }
}
