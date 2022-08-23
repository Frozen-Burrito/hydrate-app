import 'package:flutter/material.dart';

/// Un widget que muestra un [value] entero en un [Text]. Cuando [value] cambia, 
/// el [Text] de este widget transiciona desde su valor actual hacia el nuevo 
/// valor, incrementando/decrementando en pasos de 1 según sea necesario.
class CountText extends StatefulWidget {

  const CountText({
    Key? key,
    required this.value,
    this.style,
    this.textAlign,
    this.transitionCurve = Curves.easeOutCubic,
    this.transitionDuration = const Duration( milliseconds: 750 ),
  }) : super(key: key);

  /// El valor que será mostrado en el texto.
  final int value;

  /// El estilo de texto para el [Text] subyacente.
  final TextStyle? style;

  /// La alineación de contenido para el [Text] subyacente.
  final TextAlign? textAlign;

  /// La curva que controla los valores que toma este [Text] durante
  /// una transición.
  final Curve transitionCurve;

  /// El duración de la transición entre un valor anterior y uno nuevo.
  final Duration transitionDuration;

  @override
  State<CountText> createState() => _CountTextState();
}

class _CountTextState extends State<CountText> with TickerProviderStateMixin{

  late final AnimationController _controller;
  late Animation _animation;
  late final CurveTween _curveTween = CurveTween( curve: widget.transitionCurve );
  final IntTween _countTween = IntTween( begin: 0, end: 0, );

  int _countValue = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador de la animación.
    _controller = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );

    // Definir el valor final como el valor actual del widget.
    _countTween.end = widget.value;

    // Controlar el valor de _countTween con el controlador.
    _animation = _controller.drive( _countTween.chain(_curveTween) );

    // Registrar listener de cambios en la animación.
    _animation.addListener(_updateCountValue);
  }

  @override
  void didUpdateWidget(covariant CountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el inicio y final del tween.
    _countTween.begin = oldWidget.value;
    _countTween.end = widget.value;

    // Actualizar el estado de la animación.
    setState(() {
      _animation = _controller.drive( _countTween.chain(_curveTween), );
    });

    _controller.forward( from: 0.0 );
  }

  @override
  void dispose() {
    _animation.removeListener(_updateCountValue);
    _controller.dispose();
    super.dispose();
  }

  void _updateCountValue() {
    setState(() {
      _countValue = _animation.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _countValue.toString(),
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}