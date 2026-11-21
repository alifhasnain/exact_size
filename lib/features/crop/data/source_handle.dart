/// The picked image's read URI from FEAT-001, kept in memory for the flow
/// session only (tech.md section 5). Never logged or persisted: [toString]
/// is redacted because a URI can contain a file name or path.
final class SourceHandle {
  const SourceHandle(this.uri);

  /// `content://` (picker) or `file://` (tests) URI.
  final String uri;

  @override
  String toString() => 'SourceHandle(<redacted>)';
}
