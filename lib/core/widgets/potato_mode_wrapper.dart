import 'package:flutter/material.dart';

class PotatoModeWrapper extends StatelessWidget {
  final Widget child;

  const PotatoModeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
