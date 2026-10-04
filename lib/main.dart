import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app/logria_app.dart';
import 'core/database/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Logria',
    ], await rootBundle.loadString('LICENSE'));
  });
  final database = AppDatabase.defaults();
  runApp(LogriaApp(database: database));
}
