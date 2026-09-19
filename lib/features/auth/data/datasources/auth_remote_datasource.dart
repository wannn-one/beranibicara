import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'package:beranibicara/core/constants/app_constants.dart';
import 'package:beranibicara/core/errors/exceptions.dart';
import 'package:beranibicara/features/auth/data/models/user_model.dart';
import 'package:beranibicara/features/auth/data/models/nisn_registry_model.dart';
import 'package:beranibicara/features/auth/data/models/kelas_model.dart';
import 'package:beranibicara/features/auth/domain/entities/user.dart'
    as entities;
import 'package:beranibicara/features/auth/domain/entities/auth_session_event.dart';

/// Remote data source for authentication
/// Handles all Supabase Auth operations
class SignUpOutcome {
  final UserModel? user;
  final bool needsEmailConfirmation;

  const SignUpOutcome({
    this.user,
    this.needsEmailConfirmation = false,
  });
}

class AuthRemoteDataSource {
  final supabase_flutter.SupabaseClient supabaseClient;

  AuthRemoteDataSource(this.supabaseClient);

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Supabase sign in
      final authResponse = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw AuthException('Sign in failed: No user returned');
      }

      // Fetch profile data
      final profile = await _fetchProfile(authResponse.user!.id);

      return UserModel.fromSupabase(
        authUser: authResponse.user!.toJson(),
        profile: profile,
      );
    } on supabase_flutter.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(message: 'Sign in failed: $e');
    }
  }

  /// Sign in with Google OAuth
  Future<UserModel> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_CLIENT_ID']!;
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      // Trigger Google Sign-In flow
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('No ID token found');
      }

      // Sign in to Supabase with Google credentials
      final authResponse = await supabaseClient.auth.signInWithIdToken(
        provider: supabase_flutter.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (authResponse.user == null) {
        throw AuthException('Google sign in failed: No user returned');
      }

      // Fetch or create profile
      final profile = await _fetchOrCreateProfile(authResponse.user!);

      return UserModel.fromSupabase(
        authUser: authResponse.user!.toJson(),
        profile: profile,
      );
    } on supabase_flutter.AuthException catch (e) {
      if (e.message.contains('cancelled')) {
        throw AuthException('Google sign in cancelled');
      }
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(message: 'Google sign in failed: $e');
    }
  }

  /// Sign up with email and password
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
    entities.UserRole role = entities.UserRole.siswa,
    String? nisn,
  }) async {
    try {
      if (nisn != null && nisn.isNotEmpty) {
        final nisnRegistry = await verifyNisn(nisn);
        if (nisnRegistry.isRegistered || nisnRegistry.userId != null) {
          throw NisnAlreadyUsedException();
        }
      }

      final metadata = <String, dynamic>{
        'full_name': fullName,
        'role': role.value,
      };
      if (nisn != null && nisn.isNotEmpty) {
        metadata['nisn'] = nisn;
      }

      final authResponse = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: AppConstants.authCallbackUrl,
        data: metadata,
      );

      if (authResponse.user == null) {
        throw AuthException('Sign up failed: No user returned');
      }

      if (authResponse.session == null) {
        return const SignUpOutcome(needsEmailConfirmation: true);
      }

      if (nisn != null && nisn.isNotEmpty) {
        await supabaseClient
            .from('profiles')
            .update({'nisn': nisn})
            .eq('id', authResponse.user!.id);

        await supabaseClient.from('nisn_registry').update({
          'is_registered': true,
          'user_id': authResponse.user!.id,
          'registered_at': DateTime.now().toIso8601String(),
        }).eq('nisn', nisn);
      }

      final profile = await _fetchProfile(authResponse.user!.id);

      return SignUpOutcome(
        user: UserModel.fromSupabase(
          authUser: authResponse.user!.toJson(),
          profile: profile,
        ),
      );
    } on supabase_flutter.AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        throw EmailAlreadyInUseException();
      }
      throw AuthException(e.message, code: e.statusCode);
    } on NisnAlreadyUsedException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Sign up failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(message: 'Sign out failed: $e');
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = supabaseClient.auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final profile = await _fetchProfile(currentUser.id);

      return UserModel.fromSupabase(
        authUser: currentUser.toJson(),
        profile: profile,
      );
    } catch (e) {
      return null; // Return null if no session
    }
  }

  /// Verify NISN against registry
  Future<NisnRegistryModel> verifyNisn(String nisn) async {
    try {
      final response = await supabaseClient
          .from('nisn_registry')
          .select()
          .eq('nisn', nisn)
          .maybeSingle();

      if (response == null) {
        throw NisnNotFoundException(message: 'NISN not found in registry');
      }

      return NisnRegistryModel.fromJson(response);
    } catch (e) {
      if (e is NisnNotFoundException) rethrow;
      throw ServerException(message: 'NISN verification failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: AppConstants.authCallbackUrl,
      );
    } on supabase_flutter.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(message: 'Password reset failed: $e');
    }
  }

  Future<void> updatePassword(String password) async {
    try {
      await supabaseClient.auth.updateUser(
        supabase_flutter.UserAttributes(password: password),
      );
    } on supabase_flutter.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(message: 'Gagal mengubah password: $e');
    }
  }

  Future<bool> isPasswordRecoveryLaunch() async {
    try {
      final uri = await AppLinks().getInitialLink();
      return _isRecoveryUri(uri);
    } catch (_) {
      return false;
    }
  }

  Stream<AuthSessionEvent> watchAuthSession() async* {
    await for (final data in supabaseClient.auth.onAuthStateChange) {
      switch (data.event) {
        case supabase_flutter.AuthChangeEvent.passwordRecovery:
          yield AuthSessionEvent.passwordRecovery;
        case supabase_flutter.AuthChangeEvent.signedOut:
          yield AuthSessionEvent.signedOut;
        case supabase_flutter.AuthChangeEvent.signedIn:
          yield AuthSessionEvent.signedIn;
        default:
          break;
      }
    }
  }

  bool _isRecoveryUri(Uri? uri) {
    if (uri == null) return false;
    if (uri.queryParameters['type'] == 'recovery') return true;
    return uri.fragment.contains('type=recovery');
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    int? kelasId,
    String? nisn,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName != null) updates['full_name'] = fullName;
      if (kelasId != null) updates['kelas_id'] = kelasId;
      if (nisn != null) updates['nisn'] = nisn;

      if (updates.isEmpty) {
        throw ValidationException('No fields to update');
      }

      // Update profile
      await supabaseClient.from('profiles').update(updates).eq('id', userId);

      // Fetch updated profile
      final profile = await _fetchProfile(userId);
      final authUser = supabaseClient.auth.currentUser;

      if (authUser == null) {
        throw AuthException('No authenticated user');
      }

      return UserModel.fromSupabase(
        authUser: authUser.toJson(),
        profile: profile,
      );
    } catch (e) {
      throw ServerException(message: 'Profile update failed: $e');
    }
  }

  /// Fetch kelas list for profile completion
  Future<List<KelasModel>> getKelasList() async {
    try {
      final response = await supabaseClient
          .from('kelas')
          .select('id, tingkat, jurusan')
          .order('tingkat')
          .order('jurusan');

      return (response as List)
          .map((item) => KelasModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to load kelas: $e');
    }
  }

  /// Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final session = supabaseClient.auth.currentSession;
      return session != null && !session.isExpired;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Private Helper Methods
  // ============================================================================

  /// Fetch user profile from database
  Future<Map<String, dynamic>> _fetchProfile(String userId) async {
    final response = await supabaseClient
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
        throw UserNotFoundException(message: 'Profile not found for user: $userId');
    }

    return response;
  }

  /// Fetch or create profile (for OAuth users)
  Future<Map<String, dynamic>> _fetchOrCreateProfile(
    supabase_flutter.User user,
  ) async {
    try {
      return await _fetchProfile(user.id);
    } catch (e) {
      // Profile doesn't exist, it will be created by trigger
      // Wait a bit and try again
      await Future.delayed(const Duration(milliseconds: 500));
      return await _fetchProfile(user.id);
    }
  }
}
