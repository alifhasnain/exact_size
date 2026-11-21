import 'dart:io';

import '../test_support/es_resample_cases.dart';

/// SHA-256 goldens per host OS: stb's float SIMD paths may round differently
/// with another compiler (MSVC on Windows, clang on Linux CI), ADR-005.
const hostGoldens = <String, Map<String, String>>{
  'windows': {
    'photo_1200x900_to_300x300': 'ffbb4f3b1b4fb75bf50b684e4759bab53b50b88c5a6c29b8c673052a28dc956c',
    'photo_1200x900_to_300x80': '3aa8d80ce10bea6ee3079f1aa7a06e327b9c51d68442cdf1cee98bc596149c19',
    'photo_933x400_to_140x60': 'ed049371cacd4b0207d4ebc1b530d7ecd75e2812a4643501e58cc9417736e5ef',
    'photo_120x80_to_600x400': 'fcad24c24e42f06b5928606874c522555c0873281c621dcff593de5f0a28339c',
    'photo_1x1_to_300x300': 'dec16fcf71a7f80a1738b6dcd6526c4367e1534c34d97a55e0dc20c9956c746b',
    'photo_301x299_to_300x300': 'a75195f5f8984f523b232c8c1b989f7631d6a432fbc4d2a5e4fc139b02489701',
    'disc_alpha_256_to_37': 'a4c42983925776703065a54c6ce4bdd483a043bacaf6b314945acbf16805145b',
    'disc_alpha_40_to_300': 'db270c7ead880c8309ecd6f542946c82d76e27de0127413914a6356218cb61ac',
    'photo_800x600_to_200x150_mitchell': 'fba28a24d95f9ef4e46d1167c71cbe2504ada2da55433510626fe76cc303ede5',
    'photo_7x7_to_300x80': 'c56ab9badf4b0eb4245cbc081c2755b6b7f1e428a58832b93ce2f2198e6b8225',
  },
};

/// FEAT-002-T13 on the host; the emulator run is integration_test/es_resample_test.dart.
/// An OS without goldens prints them and checks only run-to-run stability.
void main() => defineEsResampleTests(goldens: hostGoldens[Platform.operatingSystem]);
