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

class CoinShape extends StatelessWidget {

  final double radius;
  const CoinShape({ this.radius = 16.0, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius + 3.0,
      height: radius,
      child: CustomPaint(
        painter: _CoinPainter(radius: radius),
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
    path.lineTo(size.width, size.height + (size.height * 0.3));
    path.lineTo(0, size.height + (size.height * 0.3));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaveImageClipper extends CustomClipper<Path> {

  @override
  getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.8, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.45, size.width, size.height * 0.45);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper oldClipper) => false;
}

class _CoinPainter extends CustomPainter {

  final double radius;

  const _CoinPainter({ this.radius = 16.0 });
  
  @override
  void paint(Canvas canvas, Size size) {
    final foregroundPaint = Paint();
    const center = Offset(0.0, 0.0);

    final backgroundPaint = Paint();
    const thicknessOffset = Offset(3.0, 0.0);

    canvas.translate(size.width / 2, size.height / 2);

    // Dibujar grosor de la moneda.
    Path thicknessPath = Path();
    thicknessPath.addOval(Rect.fromCircle(center: thicknessOffset, radius: radius));
    
    backgroundPaint.color = const Color(0xFFEFD80D);

    canvas.drawShadow(thicknessPath, Colors.black, 3, true);
    canvas.drawPath(thicknessPath, backgroundPaint);

    foregroundPaint.color = const Color(0xFFF8E21C);
    canvas.drawCircle(center, radius, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
