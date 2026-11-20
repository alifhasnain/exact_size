// Copyright (c) 2026 ExactSize authors. All rights reserved.

/// Native image codec bindings (ADR-001, ADR-002).
///
/// For now only the FEAT-004-T02 interop proof; codec wrappers come in T03/T05.
library;

import 'src/android/android_build.g.dart';
import 'src/es_probe.g.dart' as probe;

/// Adds two numbers in C (FFIgen `@Native` binding; T02 proof).
int esProbeAdd(int a, int b) => probe.es_probe_add(a, b);

/// Android `Build.VERSION.SDK_INT` (JNIgen binding; T02 proof).
int androidSdkInt() => Build$VERSION.SDK_INT;
