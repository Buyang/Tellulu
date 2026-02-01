import 'package:flutter/material.dart';

class TelluluCard extends StatelessWidget {

  const TelluluCard({
    required this.child, super.key,
    this.maxWidth = 400,
  });
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive padding
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8.0 : 12.0), // Reduced outer padding
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF9FA0CE),
                  width: isMobile ? 2.0 : 3.0, // Thinner border on mobile
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0), // Reduced inner padding
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
