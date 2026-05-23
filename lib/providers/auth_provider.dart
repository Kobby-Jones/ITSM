import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/user.dart';
import '../models/user_role.dart';

@immutable
class AuthState {
  final AppUser? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({AppUser? user, bool? loading, String? error, bool clearError = false, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState());

  // Demo accounts — one per role. Any password works for the demo.
  static const Map<String, AppUser> _demoUsers = {
    'user@goldfields.gh': AppUser(
      id: 'u-001',
      name: 'Akosua Mensah',
      email: 'user@goldfields.gh',
      department: 'Operations',
      position: 'Plant Operator',
      phone: '+233 24 555 0142',
      role: UserRole.endUser,
      company: 'Goldfields Ghana Ltd.',
      location: 'Tarkwa Mine',
    ),
    'tech@goldfields.gh': AppUser(
      id: 't-001',
      name: 'Kwame Boateng',
      email: 'tech@goldfields.gh',
      department: 'IT Operations',
      position: 'Senior IT Technician',
      phone: '+233 24 555 0188',
      role: UserRole.technician,
      company: 'Goldfields Ghana Ltd.',
      location: 'Accra HQ',
    ),
    'admin@goldfields.gh': AppUser(
      id: 'a-001',
      name: 'Esi Owusu',
      email: 'admin@goldfields.gh',
      department: 'IT Administration',
      position: 'IT Administrator',
      phone: '+233 24 555 0211',
      role: UserRole.admin,
      company: 'Goldfields Ghana Ltd.',
      location: 'Accra HQ',
    ),
    'manager@goldfields.gh': AppUser(
      id: 'm-001',
      name: 'Yaw Asante',
      email: 'manager@goldfields.gh',
      department: 'IT Leadership',
      position: 'IT Service Manager',
      phone: '+233 24 555 0299',
      role: UserRole.manager,
      company: 'Goldfields Ghana Ltd.',
      location: 'Accra HQ',
    ),
  };

  static List<({String email, String role, String name})> get demoAccounts => _demoUsers.entries
      .map((e) => (email: e.key, role: e.value.role.label, name: e.value.name))
      .toList();

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 700));

    final user = _demoUsers[email.trim().toLowerCase()];
    if (user == null) {
      state = state.copyWith(loading: false, error: 'No account found. Try one of the demo accounts.');
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(loading: false, error: 'Password is required.');
      return;
    }
    state = AuthState(user: user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String department,
    required String password,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 800));
    final user = AppUser(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      department: department,
      position: 'Staff',
      phone: '+233 24 000 0000',
      role: UserRole.endUser,
      company: 'Goldfields Ghana Ltd.',
      location: 'Accra HQ',
    );
    state = AuthState(user: user);
  }

  Future<void> requestPasswordReset(String email) async {
    state = state.copyWith(loading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(loading: false);
  }

  void logout() {
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());
