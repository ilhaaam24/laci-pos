import 'package:flutter/material.dart';

class ProBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const ProBadge({
    super.key,
    this.fontSize = 10.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: fontSize + 2.5,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }
    return badge;
  }
}
