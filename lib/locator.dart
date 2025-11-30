import 'package:get_it/get_it.dart';
import 'data/local/database.dart'; 

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
}