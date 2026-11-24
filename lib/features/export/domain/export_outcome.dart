/// FEAT-007 outcome codes, exactly PRD 1.1 section 5. [code] is the PRD spelling;
/// only these codes may be logged (FR-27).
enum ExportOutcome {
  saved('SAVED'),
  alreadySaved('ALREADY_SAVED'),
  shareOpened('SHARE_OPENED'),
  saveCancelled('SAVE_CANCELLED'),
  openNoViewer('OPEN_NO_VIEWER'),
  noSpace('NO_SPACE'),
  saveFailed('SAVE_FAILED'),
  permissionDenied('PERMISSION_DENIED'),
  fileMissing('FILE_MISSING'),
  shareFailed('SHARE_FAILED');

  const ExportOutcome(this.code);
  final String code;
}
