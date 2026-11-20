// Copyright (c) 2026 ExactSize authors. All rights reserved.

import 'package:code_assets/code_assets.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Asset id shared by every FFIgen binding file in this package.
const nativeAssetId = 'package:es_codec/es_codec_native';

const _ljt = 'third_party/libjpeg-turbo/src';

/// libjpeg-turbo 3.2.1 sources, copied from the upstream CMakeLists.txt
/// (`JPEG_SOURCES` with arithmetic coding, plus `TURBOJPEG_SOURCES` and the
/// bundled spng/zlib it needs). SIMD is off (third_party/libjpeg-turbo/VENDOR.md).
const _jpegSources = [
  'jcapimin.c',
  'wrapper/jcapistd-8.c', 'wrapper/jcapistd-12.c', 'wrapper/jcapistd-16.c',
  'wrapper/jccoefct-8.c', 'wrapper/jccoefct-12.c',
  'wrapper/jccolor-8.c', 'wrapper/jccolor-12.c', 'wrapper/jccolor-16.c',
  'wrapper/jcdctmgr-8.c', 'wrapper/jcdctmgr-12.c',
  'wrapper/jcdiffct-8.c', 'wrapper/jcdiffct-12.c', 'wrapper/jcdiffct-16.c',
  'jchuff.c', 'jcicc.c', 'jcinit.c', 'jclhuff.c',
  'wrapper/jclossls-8.c', 'wrapper/jclossls-12.c', 'wrapper/jclossls-16.c',
  'wrapper/jcmainct-8.c', 'wrapper/jcmainct-12.c', 'wrapper/jcmainct-16.c',
  'jcmarker.c', 'jcmaster.c', 'jcomapi.c', 'jcparam.c', 'jcphuff.c',
  'wrapper/jcprepct-8.c', 'wrapper/jcprepct-12.c', 'wrapper/jcprepct-16.c',
  'wrapper/jcsample-8.c', 'wrapper/jcsample-12.c', 'wrapper/jcsample-16.c',
  'jctrans.c', 'jdapimin.c',
  'wrapper/jdapistd-8.c', 'wrapper/jdapistd-12.c', 'wrapper/jdapistd-16.c',
  'jdatadst.c', 'jdatasrc.c',
  'wrapper/jdcoefct-8.c', 'wrapper/jdcoefct-12.c',
  'wrapper/jdcolor-8.c', 'wrapper/jdcolor-12.c', 'wrapper/jdcolor-16.c',
  'wrapper/jddctmgr-8.c', 'wrapper/jddctmgr-12.c',
  'wrapper/jddiffct-8.c', 'wrapper/jddiffct-12.c', 'wrapper/jddiffct-16.c',
  'jdhuff.c', 'jdicc.c', 'jdinput.c', 'jdlhuff.c',
  'wrapper/jdlossls-8.c', 'wrapper/jdlossls-12.c', 'wrapper/jdlossls-16.c',
  'wrapper/jdmainct-8.c', 'wrapper/jdmainct-12.c', 'wrapper/jdmainct-16.c',
  'jdmarker.c', 'jdmaster.c',
  'wrapper/jdmerge-8.c', 'wrapper/jdmerge-12.c',
  'jdphuff.c',
  'wrapper/jdpostct-8.c', 'wrapper/jdpostct-12.c', 'wrapper/jdpostct-16.c',
  'wrapper/jdsample-8.c', 'wrapper/jdsample-12.c', 'wrapper/jdsample-16.c',
  'jdtrans.c', 'jerror.c', 'jfdctflt.c',
  'wrapper/jfdctfst-8.c', 'wrapper/jfdctfst-12.c',
  'wrapper/jfdctint-8.c', 'wrapper/jfdctint-12.c',
  'wrapper/jidctflt-8.c', 'wrapper/jidctflt-12.c',
  'wrapper/jidctfst-8.c', 'wrapper/jidctfst-12.c',
  'wrapper/jidctint-8.c', 'wrapper/jidctint-12.c',
  'wrapper/jidctred-8.c', 'wrapper/jidctred-12.c',
  'jmemmgr.c', 'jmemnobs.c', 'jpeg_nbits.c',
  'wrapper/jquant1-8.c', 'wrapper/jquant1-12.c',
  'wrapper/jquant2-8.c', 'wrapper/jquant2-12.c',
  'wrapper/jutils-8.c', 'wrapper/jutils-12.c', 'wrapper/jutils-16.c',
  'jaricom.c', 'jcarith.c', 'jdarith.c',
  // TURBOJPEG_SOURCES
  'turbojpeg.c', 'transupp.c', 'jdatadst-tj.c', 'jdatasrc-tj.c',
  'rdbmp.c', 'wrapper/rdpng-8.c', 'wrapper/rdpng-12.c', 'wrapper/rdpng-16.c',
  'wrapper/rdppm-8.c', 'wrapper/rdppm-12.c', 'wrapper/rdppm-16.c',
  'wrbmp.c', 'wrapper/wrpng-8.c', 'wrapper/wrpng-12.c', 'wrapper/wrpng-16.c',
  'wrapper/wrppm-8.c', 'wrapper/wrppm-12.c', 'wrapper/wrppm-16.c',
  // bundled libspng and zlib (src/spng/CMakeLists.txt)
  'spng/spng.c',
  'spng/zlib/adler32.c', 'spng/zlib/compress.c', 'spng/zlib/crc32.c',
  'spng/zlib/deflate.c', 'spng/zlib/inffast.c', 'spng/zlib/inflate.c',
  'spng/zlib/inftrees.c', 'spng/zlib/trees.c', 'spng/zlib/zutil.c',
];

/// Build spec shared by hook/build.dart and hook/link.dart (ADR-001, ADR-002).
///
/// Every Android ABI (arm64-v8a, armeabi-v7a, x86_64) gets the same flags.
CLibrary codecLibrary(OS targetOS) => CLibrary(
  name: 'es_codec',
  assetName: 'es_codec_native',
  sources: [for (final s in _jpegSources) '$_ljt/$s'],
  includes: [
    'third_party/libjpeg-turbo-config', // hand-written CMake-generated headers
    _ljt,
    '$_ljt/spng',
    '$_ljt/spng/zlib',
  ],
  // Same as upstream COMPILE_FLAGS for the turbojpeg target, plus zlib's prefix.
  defines: {
    'BMP_SUPPORTED': null,
    'PNG_SUPPORTED': null,
    'PPM_SUPPORTED': null,
    'SPNG_STATIC': null,
    'Z_PREFIX': null,
    // Windows host builds (flutter test): export the TurboJPEG API from the DLL.
    if (targetOS == OS.windows) 'DLLDEFINE': null,
  },
  flags: [
    // Google Play 16 KB page size; NDK r28 does this by default, kept explicit.
    if (targetOS == OS.android) '-Wl,-z,max-page-size=16384',
  ],
);

/// Same 16 KB rule for the release link step (hook/link.dart).
List<String> linkFlags(OS targetOS) =>
    [if (targetOS == OS.android) '-z,max-page-size=16384'];
