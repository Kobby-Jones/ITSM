import 'package:flutter_riverpod/legacy.dart';

class ConnectivityController extends StateNotifier<bool> {
  ConnectivityController() : super(true);

  void toggle() => state = !state;
  void setOnline(bool online) => state = online;
}

/// `true` when the simulated device is online.
final connectivityProvider =
    StateNotifierProvider<ConnectivityController, bool>((ref) => ConnectivityController());
