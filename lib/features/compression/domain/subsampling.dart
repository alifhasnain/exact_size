/// JPEG chroma subsampling used by the size search (tech.md configs A/B/C).
enum Subsampling {
  /// 4:2:0, the base config (smaller files).
  yuv420,

  /// 4:4:4, FR-8 lever 2 (raises size, sharper colour edges).
  yuv444,
}
