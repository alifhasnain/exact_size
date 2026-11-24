package com.exactsize.exact_size

import androidx.core.content.FileProvider

/**
 * FEAT-007 (FR-5, FR-18, ADR-007): the share copy's FileProvider. Its own class because a second
 * `<provider>` entry with the plain androidx class is bound to the camera provider's authority
 * (FEAT-007-T01 spike: SecurityException "authority does not match").
 */
class ShareFileProvider : FileProvider()
