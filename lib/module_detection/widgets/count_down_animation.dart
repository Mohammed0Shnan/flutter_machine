import 'package:flutter/material.dart';

class CountdownAnimation extends StatefulWidget {
  final VoidCallback onCountdownComplete;

  const CountdownAnimation({super.key, required this.onCountdownComplete});

  @override
  State<CountdownAnimation> createState() => _CountdownAnimationState();
}

class _CountdownAnimationState extends State<CountdownAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _currentCount = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _scaleAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.addListener((){setState(() {

    });});

    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      _controller.reset();
      await _controller.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (_currentCount > 1) {
        if(mounted){
          setState(() {
            _currentCount--;
          });
        }

        return true;
      } else {
        widget.onCountdownComplete();
        return false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Text(
                '$_currentCount',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
