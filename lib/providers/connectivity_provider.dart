import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Reflects the device's *actual* network reachability (Wi-Fi/cellular/
/// ethernet vs none), backed by `connectivity_plus`. This replaced an
/// earlier version that just held a manually-toggled boolean for demo
/// purposes — every other provider now depends on this being real, since
/// it's what decides whether writes go straight to the API or into the
/// offline sync queue.
///
/// Note: connectivity_plus reports *link* status, not whether the backend
/// is actually reachable (e.g. Wi-Fi with no internet still reports
/// connected). `ApiClient`'s NetworkException handling is the backstop for
/// that case — a request can still fail and get queued even when this
/// provider says "online".
class ConnectivityController extends StateNotifier<bool> {
  ConnectivityController() : super(true) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _manualOverride = false;

  Future<void> _init() async {
    final initial = await Connectivity().checkConnectivity();
    state = _isOnline(initial);

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (_manualOverride) return;
      state = _isOnline(results);
    });
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void toggle() {
    _manualOverride = true;
    state = !state;
  }

  void setOnline(bool online) {
    state = online;
    _manualOverride = !online;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityController, bool>((ref) => ConnectivityController());
