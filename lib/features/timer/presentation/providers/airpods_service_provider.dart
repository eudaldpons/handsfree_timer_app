import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/airpods_service.dart';

final airPodsServiceProvider = Provider<AirPodsService>((ref) {
  return AirPodsService();
});
