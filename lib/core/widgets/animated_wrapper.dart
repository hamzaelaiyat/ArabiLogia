import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arabilogia/providers/potato_mode_provider.dart';

class AnimatedWrapper extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final bool addAnimation;
  final Duration delay;

  const AnimatedWrapper({
    super.key,
    required this.child,
    this.duration,
    this.addAnimation = true,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedWrapper> createState() => _AnimatedWrapperState();
}

class _AnimatedWrapperState extends State<AnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    _startAnimation();
  }

  void _startAnimation() {
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, _controller.forward);
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PotatoModeProvider>(
      builder: (context, potato, _) {
        if (!widget.addAnimation || !potato.animationsEnabled) {
          return widget.child;
        }
        return SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        );
      },
    );
  }
}
