// Copyright (c) 2026 ExactSize authors. All rights reserved.
//
// Implementation unit for the vendored stb_image_resize2 (ADR-005,
// FEAT-002-T01). The header is compiled once here; es_resample (FEAT-002-T13)
// calls it. Release builds keep only the symbols the app uses (hook/link.dart).
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h"
