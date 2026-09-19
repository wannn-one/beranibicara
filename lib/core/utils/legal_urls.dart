import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:beranibicara/core/constants/app_constants.dart';

String termsOfUseUrl() {
  final fromEnv = dotenv.env['TERMS_OF_USE_URL']?.trim();
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  return AppConstants.urlTermsOfUse;
}

String privacyPolicyUrl() {
  final fromEnv = dotenv.env['PRIVACY_POLICY_URL']?.trim();
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  return AppConstants.urlPrivacyPolicy;
}
