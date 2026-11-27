/// FEAT-011-T08: the synthetic library of test/presets/fixtures/test_library.json, inline,
/// because files under test/ are not on the device. test/presets/fixture_data_test.dart keeps
/// the two equal. Synthetic values only; not a real form.
const presetFixtureLibrary = <String, Object?>{
  'schema': 1,
  'forms': [
    {
      'id': 'test-form-a',
      'name': 'Test Form A',
      'issuer': 'Test Issuer',
      'country': 'ZZ',
      'category': 'exam_admission',
      'aliases': ['TFA'],
      'source': {'title': 'Test notice 1', 'url': '[PLACEHOLDER]'},
      'lastChecked': '2026-10-01',
      'specs': [
        {
          'kind': 'photo',
          'width': 200,
          'height': 230,
          'minKb': 20,
          'maxKb': 50,
          'format': 'jpeg',
          'notCovered': [
            {'code': 'dpi', 'dpi': 200},
            {'code': 'background'},
          ],
        },
        {'kind': 'signature', 'width': 140, 'height': 60, 'minKb': null, 'maxKb': 20, 'format': 'jpeg'},
      ],
    },
    {
      'id': 'test-form-b',
      'name': 'Test Form B',
      'issuer': 'Test Board',
      'country': 'ZZ',
      'category': 'job',
      'aliases': <String>[],
      'source': {'title': 'Test notice 2', 'url': '[PLACEHOLDER]'},
      'lastChecked': '2026-11-20',
      'specs': [
        {
          'kind': 'photo',
          'width': 300,
          'height': 300,
          'minKb': 10,
          'maxKb': 100,
          'format': 'jpeg',
          'notCovered': [
            {'code': 'content'},
          ],
        },
      ],
    },
    {
      'id': 'test-form-c',
      'name': 'Test Form C',
      'issuer': 'Test Office',
      'country': 'ZZ',
      'category': 'visa_passport',
      'aliases': <String>[],
      'source': {'title': 'Test notice 3', 'url': '[PLACEHOLDER]'},
      'lastChecked': '2026-11-20',
      'specs': [
        {'kind': 'photo', 'width': null, 'height': null, 'minKb': 10, 'maxKb': 200, 'format': 'jpeg'},
      ],
    },
  ],
};
