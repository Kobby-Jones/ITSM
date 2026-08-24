import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Reflects the device's network reachability.
///
/// On **mobile** (Android/iOS) this uses `connectivity_plus` which
/// reports link status reliably.
///
/// On **desktop** (Windows/macOS/Linux) and **web**, `connectivity_plus`
/// frequently reports `none` incorrectly. For those platforms we default
/// to `true` (online) and only flip to `false` when API calls actually
/// fail — which is handled by the ApiClient's error mapping.
class ConnectivityController extends StateNotifier<bool> {
  ConnectivityController() : super(true) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _manualOverride = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _init() async {
    if (!_isMobile) {
      // Desktop/web: trust we're online; API errors are the backstop.
      state = true;
      return;
    }

    try {
      final initial = await Connectivity().checkConnectivity();
      state = _isOnline(initial);

      _sub = Connectivity().onConnectivityChanged.listen((results) {
        if (_manualOverride) return;
        state = _isOnline(results);
      });
    } catch (_) {
      // connectivity_plus threw — assume online.
      state = true;
    }
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
    StateNotifierProvider<ConnectivityController, bool>(
        (ref) => ConnectivityController());
