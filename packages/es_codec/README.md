# es_codec

Native image codecs for ExactSize (ADR-001, ADR-002): the bundled libjpeg-turbo, called through
Dart FFI (FFIgen bindings), plus small Android API bindings (JNIgen).

## Pinned native code
| Library | Version | Pin | Licences |
|---|---|---|---|
| libjpeg-turbo | **3.2.1** (tag `3.2.1`) | tarball SHA-256 `c27ad72a68da151177929aa969ae773a2da5ac2af9ce946079314fdac8cece7f`; vendored tree checksum `0657711012ae542192c73d11a213f083fc1ab5f01eee6d9838f98994242b9db3` (checked by `hook/build.dart` on every build) | IJG, Modified BSD, zlib; bundled libspng (BSD-2) and zlib |

Provenance, signature check and upgrade steps: [`third_party/libjpeg-turbo/VENDOR.md`](third_party/libjpeg-turbo/VENDOR.md).
The licence texts ship as package assets and are added to the app's licence page by
`registerEsCodecLicenses()` (called in `main()`).

## Security watch (CVE)
libjpeg-turbo parses and writes image data, so its security fixes matter even though ExactSize only
encodes. Check at least once per release and whenever a security release is announced:
- https://github.com/libjpeg-turbo/libjpeg-turbo/security/advisories and the project's releases page;
- the NVD/CVE database, searching for "libjpeg-turbo".

stb_image_resize2 (`third_party/stb`, ADR-005) resamples decoded pixels. Check it on the same schedule:
- https://github.com/nothings/stb_image_resize issues, pull requests and commits (upstream discusses
  security bugs in public there);
- the NVD/CVE database, searching for "stb_image_resize".

An upgrade follows the steps in the library's `VENDOR.md` and regenerates the golden files (ADR-002
and ADR-005 pinning rule).

## Regenerating bindings
- FFI: `dart run tool/ffigen.dart` (needs LLVM/libclang).
- JNI: `dart run tool/jnigen.dart` (needs a JDK 17–21).
