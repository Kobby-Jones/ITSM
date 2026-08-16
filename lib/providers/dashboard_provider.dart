import 'package:flutter_riverpod/legacy.dart';

import '../services/dashboard_service.dart';

enum DashboardLoadState { loading, loaded, error }

class DashboardState {
  final DashboardKpis kpis;
  final DashboardLoadState loadState;
  final String? error;

  const DashboardState({
    this.kpis = const DashboardKpis(),
    this.loadState = DashboardLoadState.loading,
    this.error,
  });

  DashboardState copyWith({
    DashboardKpis? kpis,
    DashboardLoadState? loadState,
    String? error,
  }) =>
      DashboardState(
        kpis: kpis ?? this.kpis,
        loadState: loadState ?? this.loadState,
        error: error,
      );
}

class DashboardController extends StateNotifier<DashboardState> {
  DashboardController() : super(const DashboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loadState: DashboardLoadState.loading);
    try {
      final kpis = await DashboardService.instance.getKpis();
      state = DashboardState(kpis: kpis, loadState: DashboardLoadState.loaded);
    } catch (e) {
      state = state.copyWith(
        loadState: DashboardLoadState.error,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => load();
}

final dashboardProvider =
    StateNotifierProvider<DashboardController, DashboardState>(
        (ref) => DashboardController());
