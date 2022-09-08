import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_ns/liquid_progress_indicator.dart';

class LiquidLinearProgressIndicatorPage extends StatelessWidget {
  final double value;

  LiquidLinearProgressIndicatorPage({this.value = 0.25});

  @override
  Widget build(BuildContext context) {
    return _AnimatedLiquidLinearProgressIndicator(value: value);
  }
}

class _AnimatedLiquidLinearProgressIndicator extends StatefulWidget {

  final double value;
  _AnimatedLiquidLinearProgressIndicator({required this.value});

  @override
  State<StatefulWidget> createState() =>
      _AnimatedLiquidLinearProgressIndicatorState();
}

class _AnimatedLiquidLinearProgressIndicatorState
    extends State<_AnimatedLiquidLinearProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    );

    _animationController.addListener(() => setState(() {}));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _animationController.value * 100;
    return Center(
      child: Container(
        width: double.infinity,
        height: 25.0,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: LiquidLinearProgressIndicator(
          value: widget.value,//_animationController.value,
          backgroundColor: Colors.white,
          valueColor: AlwaysStoppedAnimation(Colors.blue),
          borderRadius: 10.0,
          borderColor: Colors.red,
          borderWidth: 3.0,
          center:  Text(
            "${(widget.value * 100)}%",
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}