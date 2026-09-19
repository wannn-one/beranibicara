import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beranibicara/core/constants/app_colors.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/shared/widgets/auth_logo.dart';
import 'package:beranibicara/shared/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: AuthLogo(width: 300, height: 300),
                  ),

                  const Spacer(flex: 3),

                  CustomButton(
                    text: 'Log In',
                    onPressed: () {
                      context.go(AppConstants.routeLogin);
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomButton(
                    text: 'Sign Up',
                    backgroundColor: AppColors.white,
                    textColor: AppColors.black,
                    onPressed: () {
                      context.go(AppConstants.routeRegister);
                    },
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}