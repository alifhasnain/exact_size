import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// FEAT-001-T10/T11 debug-only page for the manual bridge checks (gallery and camera:
/// open, pick, cancel, double tap, pending capture marker). Shows the launch outcomes and the result outcome only, never the URI.
/// Run: flutter run -t integration_test/pick_bridge_demo.dart
const _ch = MethodChannel('exactsize/system_picker');

void main() => runApp(const MaterialApp(home: _Demo()));

class _Demo extends StatefulWidget {
  const _Demo();
  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  String launches = '-', result = '-', camera = '-', pending = '-', duringCamera = '-';
  int ready = 0;

  @override
  void initState() {
    super.initState();
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'resultReady') {
        ready++;
        await _take();
      }
    });
    _take();
  }

  Future<void> _take() async {
    final r = await _ch.invokeMapMethod<String, Object?>('takeResult');
    if (r == null) return;
    final uri = r['uri'] as String?;
    setState(() => result = 'origin=${r['origin']} outcome=${r['outcome']} scheme=${uri == null ? '-' : Uri.parse(uri).scheme} '
        'hasName=${r['fileName'] != null}');
  }

  Future<void> _status() async {
    final a = await _ch.invokeMethod<bool>('cameraAvailable');
    final p = await _ch.invokeMethod<String>('pendingCaptureName');
    setState(() {
      camera = '$a';
      pending = p == null ? 'null' : 'set';
    });
  }

  Future<void> _launch(int times, [String source = 'gallery']) async {
    final out = await Future.wait([
      for (var i = 0; i < times; i++) _ch.invokeMethod<String>('launch', {'source': source}),
    ]);
    setState(() => launches = out.join(','));
    // T11: read the marker while the camera app is in front (the engine keeps running).
    if (source == 'camera' && out.first == 'launched') {
      await Future<void>.delayed(const Duration(seconds: 3));
      final p = await _ch.invokeMethod<String>('pendingCaptureName');
      setState(() => duringCamera = p == null ? 'null' : 'set');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Wrap(spacing: 8, children: [
              FilledButton(onPressed: () => _launch(1), child: const Text('GALLERY')),
              FilledButton(onPressed: () => _launch(2), child: const Text('GALLERY x2')),
              FilledButton(onPressed: () => _launch(1, 'camera'), child: const Text('CAMERA')),
              OutlinedButton(onPressed: _status, child: const Text('STATUS')),
            ]),
            Text('CAMERA APP $camera  PENDING $pending  DURING $duringCamera'),
            Text('LAUNCH $launches'),
            Text('READY $ready'),
            Text('RESULT $result'),
          ]),
        ),
      );
}
