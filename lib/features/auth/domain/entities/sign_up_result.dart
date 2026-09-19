import 'package:equatable/equatable.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart';

class SignUpResult extends Equatable {
  final User? user;
  final bool needsEmailConfirmation;

  const SignUpResult({
    this.user,
    required this.needsEmailConfirmation,
  });

  @override
  List<Object?> get props => [user, needsEmailConfirmation];
}
