import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  // Sign Up
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    notifyListeners();
    return response;
  }

  // Sign In
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    notifyListeners();
    return response;
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : 'cuet://reset-password',
    );
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Verify OTP
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    required OtpType type,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
    notifyListeners();
    return response;
  }

  // Sign In with OTP (for magic links or recovery codes)
  Future<void> signInWithOtp(String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }
}
