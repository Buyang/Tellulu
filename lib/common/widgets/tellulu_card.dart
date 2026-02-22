import 'package:flutter/material.dart';

class TelluluCard extends StatelessWidget {

  const TelluluCard({
    required this.child, super.key,
    this.maxWidth = 400,
    this.isScrollable = true, // Default to true to preserve existing behavior
  });
  final Widget child;
  final double maxWidth;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive padding
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    final cardContent = Padding(
      padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF9FA0CE),
              width: isMobile ? 2.0 : 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: child,
        ),
      ),
    );

    return Center(
      child: isScrollable 
        ? SingleChildScrollView(child: cardContent) 
        : cardContent,
    );
  }
}
