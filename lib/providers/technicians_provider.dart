import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/technician.dart';
import '../services/technicians_service.dart';

class TechniciansController extends StateNotifier<List<Technician>> {
  TechniciansController() : super(const []) {
    load();
  }

  Future<void> load() async {
    try {
      state = await TechniciansService.instance.getTechnicians();
    } catch (_) {
      // Leave state as-is; the manager screens that read this should treat
      // an empty list as "couldn't load" and offer a retry if desired.
    }
  }

  Future<void> refresh() => load();
}

final techniciansControllerProvider =
    StateNotifierProvider<TechniciansController, List<Technician>>((ref) => TechniciansController());

/// Kept for backwards compatibility with screens expecting a plain list.
final techniciansProvider = Provider<List<Technician>>((ref) => ref.watch(techniciansControllerProvider));
