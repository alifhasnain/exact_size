// Copyright (c) 2026 ExactSize authors. All rights reserved.
// FEAT-004-T02 interop proof (throwaway). Replaced by the codec wrappers in T03/T05.

#ifndef ES_PROBE_H_
#define ES_PROBE_H_

#include <stdint.h>

// Used by the integration test: must survive tree shaking.
int32_t es_probe_add(int32_t a, int32_t b);

// Never called from Dart: must be removed by the link hook in release builds.
int32_t es_probe_unused(void);

#endif  // ES_PROBE_H_
