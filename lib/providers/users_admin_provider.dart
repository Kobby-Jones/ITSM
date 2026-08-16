import 'package:flutter_riverpod/legacy.dart';

import '../models/user.dart';
import '../services/users_admin_service.dart';

enum UsersLoadState { loading, loaded, error }

class UsersAdminState {
  final List<AppUser> users;
  final int total;
  final UsersLoadState loadState;
  final String? error;

  const UsersAdminState({
    this.users = const [],
    this.total = 0,
    this.loadState = UsersLoadState.loading,
    this.error,
  });
}

class UsersAdminController extends StateNotifier<UsersAdminState> {
  UsersAdminController() : super(const UsersAdminState()) {
    load();
  }

  int _currentPage = 1;
  String? _lastSearch;

  Future<void> load({String? search}) async {
    _currentPage = 1;
    _lastSearch = search;
    state = const UsersAdminState(loadState: UsersLoadState.loading);
    try {
      final result = await UsersAdminService.instance.getUsers(
        page: 1,
        search: search,
      );
      state = UsersAdminState(
        users: result.users,
        total: result.total,
        loadState: UsersLoadState.loaded,
      );
    } catch (e) {
      state = UsersAdminState(
        loadState: UsersLoadState.error,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.users.length >= state.total) return;
    _currentPage++;
    try {
      final result = await UsersAdminService.instance.getUsers(
        page: _currentPage,
        search: _lastSearch,
      );
      final existingIds = state.users.map((u) => u.id).toSet();
      final newOnes = result.users.where((u) => !existingIds.contains(u.id));
      state = UsersAdminState(
        users: [...state.users, ...newOnes],
        total: result.total,
        loadState: UsersLoadState.loaded,
      );
    } catch (_) {
      _currentPage--;
    }
  }

  Future<void> refresh() => load(search: _lastSearch);

  Future<void> deactivateUser(String userId) async {
    await UsersAdminService.instance.deactivateUser(userId);
    await refresh();
  }

  Future<void> activateUser(String userId) async {
    await UsersAdminService.instance.activateUser(userId);
    await refresh();
  }
}

final usersAdminProvider =
    StateNotifierProvider<UsersAdminController, UsersAdminState>(
        (ref) => UsersAdminController());
