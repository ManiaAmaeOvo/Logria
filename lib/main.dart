import 'package:flutter/material.dart';

import 'app/logria_app.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase.defaults();
  runApp(LogriaApp(database: database));
}
