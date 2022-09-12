import 'package:flutter/material.dart';

class AssetFadeInImage extends StatefulWidget {

  const AssetFadeInImage({
    Key? key,
    required this.image,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  final String image;

  final Duration duration;

  @override
  State<AssetFadeInImage> createState() => _AssetFadeInImageState();
}

class _AssetFadeInImageState extends State<AssetFadeInImage>  
    with TickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(
    duration: widget.duration,
    vsync: this,
  );

  late final Animation<double> _opacityAnimation = CurvedAnimation(
    parent: _controller, 
    curve: Curves.decelerate
  );

  @override
  void initState() {
    super.initState();

    _controller.forward();

    _opacityAnimation.addListener(() {
      print(_opacityAnimation.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Image( 
          image: AssetImage(widget.image),
        ),
      ),
    );
  }
}
