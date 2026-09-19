import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/shared/widgets/auth_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final location = GoRouterState.of(context).matchedLocation;
    if (location != AppConstants.routeSplash) return;
    context.go(AppConstants.routeWelcome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/background.png",
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: AuthLogo(width: 500, height: 300, fit: BoxFit.contain),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Welcome",
                  style: TextStyle(
                    fontFamily: 'LilyScriptOne',
                    fontSize: 45,
                    color: Color(0xFF3C83A8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
