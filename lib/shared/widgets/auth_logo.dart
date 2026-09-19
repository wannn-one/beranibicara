import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    this.width = 200,
    this.height = 200,
    this.fit = BoxFit.cover,
  });

  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/logo.png',
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
