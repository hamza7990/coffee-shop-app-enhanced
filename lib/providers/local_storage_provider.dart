import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_storage_repository.dart';

// Late initialization, we will override this in main()
final localStorageProvider = Provider<LocalStorageRepository>((ref) {
  throw UnimplementedError();
});
