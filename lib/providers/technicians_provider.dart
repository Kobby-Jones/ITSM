import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/technician.dart';
import '../features/manager/mock_technician_data.dart';

final techniciansProvider = Provider<List<Technician>>((ref) => MockTechnicianData.generate());
