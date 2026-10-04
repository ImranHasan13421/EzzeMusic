import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// Renders a single-line text that animates with Marquee ONLY if it overflows
/// its parent's width constraints. Otherwise displays standard ellipsis text.
class SmartMarquee extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double velocity;
  final double blankSpace;
  final TextAlign textAlign;

  const SmartMarquee({
    super.key,
    required this.text,
    required this.style,
    this.velocity = 35.0,
    this.blankSpace = 30.0,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: text, style: style);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final willOverflow = textPainter.width > constraints.maxWidth;

        if (willOverflow) {
          return Marquee(
            text: '$text   •   ',
            style: style,
            velocity: velocity,
            blankSpace: blankSpace,
          );
        }

        return Text(
          text,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        );
      },
    );
  }
}
