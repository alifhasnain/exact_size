import 'package:es_codec/es_codec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'di/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  registerEsCodecLicenses();
  runApp(const ProviderScope(child: ExactSizeApp()));
}
