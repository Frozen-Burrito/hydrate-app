import 'package:flutter/material.dart';

class WaveShape extends StatelessWidget {
  const WaveShape({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: CustomPaint(
        painter: _WaveShapePainter(Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class RoundedRectangle extends StatelessWidget {
  const RoundedRectangle({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50.0)
        )
      ),
    );
  }
}

class _WaveShapePainter extends CustomPainter {

  final Color primaryColor;

  const _WaveShapePainter(this.primaryColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.color = primaryColor;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 1.0;

    final path = Path();

    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.7, size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.75);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}