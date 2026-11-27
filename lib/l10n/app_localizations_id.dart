// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'ExactSize';

  @override
  String kbAmount(String amount) {
    return '$amount KB';
  }

  @override
  String kbRange(String min, String max) {
    return '$min–$max KB';
  }

  @override
  String outcomeCantReachRange(String range, String achieved) {
    return 'Kami tidak dapat mencapai $range untuk gambar ini pada dimensi ini. Hasil terdekat: $achieved.';
  }

  @override
  String outcomeCantReachMax(String max, String achieved) {
    return 'Kami tidak dapat memperkecil ukuran file gambar ini hingga $max pada dimensi ini. Hasil terdekat: $achieved.';
  }

  @override
  String get outcomeHintJpegWouldFit =>
      'Sebagai JPEG, gambar ini akan sesuai dengan ukuran yang diminta.';

  @override
  String get outcomeHintTryJpeg =>
      'Ukuran file PNG tidak dapat ditambah. Jika formulir menerima JPEG, coba gunakan JPEG.';

  @override
  String get outcomeUnsupportedInput =>
      'Jenis file ini tidak didukung di perangkat ini.';

  @override
  String get outcomeImageTooLarge =>
      'Gambar ini terlalu besar untuk diproses pada dimensi ini. Coba dimensi yang lebih kecil.';

  @override
  String get outcomeOutOfMemory =>
      'Memori ponsel Anda tidak cukup. Tutup aplikasi lain, lalu coba lagi.';

  @override
  String get outcomeWriteFailed =>
      'File tidak dapat disimpan. Kosongkan sebagian ruang penyimpanan, lalu coba lagi.';

  @override
  String get outcomeCancelled => 'Kompresi dibatalkan.';

  @override
  String get outcomeInternalError =>
      'Terjadi masalah saat menyiapkan gambar Anda. Silakan coba lagi.';

  @override
  String get noticeNarrowRange =>
      'Rentang ukuran ini sangat sempit. Beberapa portal menghitung KB dengan cara berbeda, sehingga file masih dapat ditolak.';

  @override
  String get noticePaddingAdded =>
      'Data pengisi ditambahkan ke file untuk mencapai ukuran minimum. Gambar itu sendiri tidak berubah.';

  @override
  String get noticeTransparencyFlattened =>
      'JPEG tidak mendukung transparansi, jadi area transparan sekarang berwarna putih.';

  @override
  String announceProgress(String pass, String total) {
    return 'Mengompresi, langkah $pass dari $total.';
  }

  @override
  String announceSuccess(String size) {
    return 'Selesai. Ukuran file: $size.';
  }

  @override
  String targetMaxOutOfRange(String min, String max) {
    return 'Masukkan ukuran maksimum antara $min dan $max.';
  }

  @override
  String get targetMinNotBelowMax =>
      'Ukuran minimum harus lebih kecil daripada ukuran maksimum.';

  @override
  String get targetWholeNumbersOnly => 'Gunakan bilangan bulat untuk KB.';

  @override
  String get targetInvalidNumber => 'Masukkan ukuran yang valid dalam KB.';

  @override
  String get targetChooseJpegOrPng => 'Pilih JPEG atau PNG.';

  @override
  String pixelSize(String width, String height) {
    return '$width×$height';
  }

  @override
  String cropTargetSideOutOfRange(String min, String max) {
    return 'Masukkan lebar dan tinggi antara $min dan $max piksel.';
  }

  @override
  String get cropTargetTooLarge =>
      'Dimensi itu terlalu besar untuk aplikasi ini. Pilih dimensi yang lebih kecil.';

  @override
  String get cropSourceTooLarge =>
      'Foto ini terlalu besar untuk dibuka di perangkat ini. Pilih foto lain.';

  @override
  String get cropUnsupportedInput =>
      'Jenis file ini tidak didukung di perangkat ini. Pilih foto JPEG atau PNG.';

  @override
  String get cropCorruptInput =>
      'Kami tidak dapat membaca file ini. Pilih foto lain.';

  @override
  String get cropSourceUnavailable =>
      'Kami tidak dapat menemukan foto ini lagi. Silakan pilih ulang.';

  @override
  String get cropOutOfMemory =>
      'Foto ini terlalu besar untuk perangkat ini. Coba foto yang lebih kecil.';

  @override
  String get cropCancelled => 'Proses dibatalkan. Foto Anda tidak diubah.';

  @override
  String cropNoticeEnlarged(String size) {
    return 'Foto ini lebih kecil dari $size piksel, jadi akan diperbesar dan mungkin terlihat kurang tajam.';
  }

  @override
  String cropConfirmEnlarge(String factor) {
    return 'Foto ini jauh lebih kecil dari yang dibutuhkan (diperbesar $factor×) dan mungkin terlihat buram. Tetap lanjutkan?';
  }

  @override
  String get cropNoticeAnimated =>
      'Gambar ini beranimasi. Hanya frame pertama yang digunakan.';

  @override
  String get cropHintLimitedPrecision =>
      'Area pangkas tampak sangat sempit di layar. Gunakan tombol geser dan zoom untuk mengatur posisi dengan tepat.';

  @override
  String get cropButtonCentre => 'Tengahkan';

  @override
  String get cropButtonReset => 'Atur ulang';

  @override
  String get cropButtonMoveLeft => 'Geser ke kiri';

  @override
  String get cropButtonMoveRight => 'Geser ke kanan';

  @override
  String get cropButtonMoveUp => 'Geser ke atas';

  @override
  String get cropButtonMoveDown => 'Geser ke bawah';

  @override
  String get cropButtonZoomIn => 'Perbesar tampilan';

  @override
  String get cropButtonZoomOut => 'Perkecil tampilan';

  @override
  String get cropButtonRotateClockwise => 'Putar searah jarum jam';

  @override
  String get cropButtonRotateCounterclockwise =>
      'Putar berlawanan arah jarum jam';

  @override
  String get cropButtonContinue => 'Lanjutkan';

  @override
  String get cropButtonContinueAnyway => 'Tetap lanjutkan';

  @override
  String get cropButtonChooseAnother => 'Pilih foto lain';

  @override
  String cropAreaState(String zoom, String position) {
    String _temp0 = intl.Intl.selectLogic(position, {
      'centre': 'bagian tengah',
      'top': 'bagian atas',
      'bottom': 'bagian bawah',
      'left': 'bagian kiri',
      'right': 'bagian kanan',
      'topLeft': 'bagian kiri atas',
      'topRight': 'bagian kanan atas',
      'bottomLeft': 'bagian kiri bawah',
      'bottomRight': 'bagian kanan bawah',
      'other': 'sebagian',
    });
    return 'Area pangkas, zoom $zoom, menampilkan $_temp0 foto';
  }

  @override
  String cropEdgeReached(String edge) {
    String _temp0 = intl.Intl.selectLogic(edge, {
      'left': 'kiri',
      'right': 'kanan',
      'top': 'atas',
      'bottom': 'bawah',
      'other': '',
    });
    return 'Sudah mencapai tepi $_temp0.';
  }

  @override
  String cropHandleLabel(String corner) {
    String _temp0 = intl.Intl.selectLogic(corner, {
      'topLeft': 'kiri atas',
      'topRight': 'kanan atas',
      'bottomLeft': 'kiri bawah',
      'bottomRight': 'kanan bawah',
      'other': '',
    });
    return 'Ubah ukuran area pangkas, sudut $_temp0';
  }

  @override
  String get cropAnnounceNoEnlargement => 'Foto tidak perlu diperbesar lagi.';

  @override
  String cropAnnounceStrongEnlargement(String factor) {
    return 'Pembesaran tinggi ($factor×). Anda akan diminta mengonfirmasi sebelum melanjutkan.';
  }

  @override
  String get pickTakePhoto => 'Ambil foto';

  @override
  String get pickChooseGallery => 'Pilih dari galeri';

  @override
  String get pickChooseFiles => 'Pilih dari file';

  @override
  String get pickPrivacyNote =>
      'Foto Anda diubah ukurannya di ponsel Anda. ExactSize tidak pernah mengunggahnya.';

  @override
  String get pickOpening => 'Membuka foto Anda…';

  @override
  String get pickNoCamera =>
      'Tidak ada aplikasi kamera di ponsel ini. Sebagai gantinya, pilih foto dari galeri.';

  @override
  String get pickPickerUnavailable =>
      'Kami tidak dapat membuka pemilih foto. Coba lagi atau ambil foto.';

  @override
  String get pickCameraNoPhoto =>
      'Tidak ada foto yang diterima dari kamera. Silakan coba lagi.';

  @override
  String get pickLowSpace =>
      'Ruang penyimpanan di ponsel ini tidak cukup untuk mengambil foto. Kosongkan sebagian ruang penyimpanan atau pilih foto dari galeri.';

  @override
  String get pickCaptureLost =>
      'Foto hilang saat kamera terbuka. Silakan ambil foto lagi.';

  @override
  String get pickItemNotOpenable =>
      'Kami tidak dapat membuka item itu. Sebagai gantinya, pilih foto.';

  @override
  String get pickSourceUnavailable =>
      'Kami tidak dapat membuka foto ini. Jika foto tersimpan di cloud, sambungkan ponsel ke internet atau pilih foto yang tersimpan di ponsel ini.';

  @override
  String get targetPixelsNotWhole => 'Gunakan bilangan bulat untuk piksel.';

  @override
  String get targetLabelWidth => 'Lebar';

  @override
  String get targetLabelHeight => 'Tinggi';

  @override
  String get targetLabelMin => 'Ukuran minimum';

  @override
  String get targetLabelMax => 'Ukuran maksimum';

  @override
  String get targetOptional => 'Opsional';

  @override
  String get targetUnitPx => 'piksel';

  @override
  String get targetUnitKb => 'KB';

  @override
  String get targetFormatLabel => 'Format';

  @override
  String targetPhotoSize(String size) {
    return 'Foto Anda: $size piksel';
  }

  @override
  String get targetUsePhotoSize => 'Gunakan dimensi foto';

  @override
  String get targetHintVerySmall =>
      'Gambar akan sangat kecil. Periksa dimensi yang diminta formulir Anda.';

  @override
  String get exportSave => 'Simpan';

  @override
  String get exportShare => 'Bagikan';

  @override
  String get exportSaveAs => 'Pilih lokasi penyimpanan';

  @override
  String get exportOpen => 'Buka';

  @override
  String get exportDone => 'Selesai';

  @override
  String exportSaved(String folder, String fileName) {
    return 'File disimpan di $folder sebagai $fileName.';
  }

  @override
  String exportSavedAs(String fileName) {
    return 'File disimpan sebagai $fileName.';
  }

  @override
  String exportAlreadySaved(String fileName, String folder) {
    return 'File ini sudah disimpan sebagai $fileName di $folder.';
  }

  @override
  String exportAlreadySavedAs(String fileName) {
    return 'File ini sudah disimpan sebagai $fileName.';
  }

  @override
  String get exportNoSpace =>
      'Ruang penyimpanan di ponsel ini tidak cukup untuk menyimpan file. Kosongkan sebagian ruang penyimpanan, lalu coba lagi.';

  @override
  String get exportSaveFailed =>
      'File tidak dapat disimpan. Coba lagi atau bagikan file sebagai gantinya.';

  @override
  String get exportPermissionDenied =>
      'ExactSize memerlukan izin penyimpanan untuk menyimpan ke galeri Anda. Izinkan akses penyimpanan di Setelan. Anda juga dapat membagikan file atau memilih lokasi penyimpanan.';

  @override
  String get exportFileMissing =>
      'File hasil tidak tersedia lagi. Foto di galeri Anda tetap seperti semula. Pilih ulang foto untuk membuat file baru.';

  @override
  String get exportShareFailed =>
      'Menu berbagi tidak dapat dibuka. Coba lagi atau simpan file sebagai gantinya.';

  @override
  String get exportNoViewer =>
      'Tidak ada aplikasi di ponsel ini yang dapat membuka file ini. Anda tetap dapat membagikannya.';

  @override
  String get exportPrivacy =>
      'Jika Anda menyimpan, salinan disimpan ke galeri Anda atau folder yang Anda pilih. Jika Anda membagikan, aplikasi yang Anda pilih menerima salinan.';

  @override
  String get exportShareHint =>
      'Beberapa aplikasi chat mengompres foto. Untuk formulir, simpan file, lalu pilih file itu saat mengunggah.';

  @override
  String get exportLeaveTitle => 'Kembali tanpa menyimpan?';

  @override
  String get exportLeaveBody =>
      'File hasil akan dihapus. Foto di galeri Anda tetap seperti semula.';

  @override
  String get exportStay => 'Tetap di sini';

  @override
  String get exportLeave => 'Kembali';

  @override
  String get exportSaving => 'Menyimpan…';

  @override
  String get checkMatches => 'Memenuhi persyaratan Anda';

  @override
  String get checkMismatch =>
      'File ini tidak memenuhi persyaratan Anda, jadi tidak dapat disimpan atau dibagikan. Kembali dan coba lagi.';

  @override
  String get checkLabelPixels => 'Dimensi dalam piksel';

  @override
  String get checkLabelFileSize => 'Ukuran file';

  @override
  String get checkLabelFormat => 'Format';

  @override
  String get checkTarget => 'Persyaratan';

  @override
  String get checkThisFile => 'File ini';

  @override
  String get checkMeets => 'Memenuhi';

  @override
  String get checkDoesntMeet => 'Tidak memenuhi';

  @override
  String checkUpToKb(String max) {
    return 'Hingga $max';
  }

  @override
  String checkPixels(String width, String height) {
    return '$width × $height piksel';
  }

  @override
  String checkAlsoFits1024(String kb, String bytes) {
    return 'Juga memenuhi jika portal Anda menghitung $kb sebagai $bytes byte.';
  }

  @override
  String get checkCaveat =>
      'Kami memeriksa piksel, KB, dan format. Beberapa formulir juga memeriksa fotonya sendiri, seperti wajah atau latar belakang.';

  @override
  String get previewCaption =>
      'Ditampilkan dengan ukuran yang disesuaikan agar muat di layar Anda.';

  @override
  String previewAlt(String width, String height, String format) {
    return 'Pratinjau file hasil Anda, $width × $height piksel, $format.';
  }

  @override
  String get previewUnavailable =>
      'Pratinjau tidak tersedia. Hasil pemeriksaan di bawah tetap berlaku.';

  @override
  String checkRowSentence(
    String label,
    String target,
    String measured,
    String status,
  ) {
    return '$label: persyaratan $target, file ini $measured, $status.';
  }

  @override
  String get privacyEntry => 'Cara foto Anda ditangani';

  @override
  String get privacyTitle => 'Foto dan privasi Anda';

  @override
  String get privacyOnPhoneTitle => 'Di ponsel Anda';

  @override
  String get privacyOnPhone =>
      'ExactSize mengubah ukuran foto Anda di ponsel Anda. ExactSize tidak pernah mengunggah foto Anda. Anda tidak perlu akun.';

  @override
  String get privacyOfflineTitle => 'Berfungsi tanpa koneksi internet';

  @override
  String get privacyOffline =>
      'Setiap langkah berfungsi tanpa koneksi internet. Foto yang hanya ada di cloud harus diunduh terlebih dahulu ke ponsel oleh aplikasi galeri Anda.';

  @override
  String get privacyKeptTitle => 'Apa yang disimpan sementara oleh ExactSize';

  @override
  String get privacyKept =>
      'ExactSize menyimpan salinan sementara hanya selama Anda bekerja. Salinan ini dihapus saat Anda selesai, atau saat aplikasi dibuka kembali. Log ExactSize hanya berisi kode status singkat, tidak pernah foto Anda.';

  @override
  String get privacyCopiesTitle => 'Saat Anda menyimpan atau membagikan';

  @override
  String get privacyCopies =>
      'Jika Anda menyimpan, salinan disimpan ke galeri Anda atau folder yang Anda pilih. Jika Anda membagikan, aplikasi yang Anda pilih menerima salinan. Setelah itu, salinan tersebut milik Anda, dan ExactSize tidak lagi mengendalikannya.';

  @override
  String get privacyOutsideTitle => 'Aplikasi lain di ponsel Anda';

  @override
  String get privacyOutside =>
      'Galeri, keyboard, dan aplikasi tempat Anda berbagi mengikuti kebijakan privasinya masing-masing. Beberapa di antaranya dapat mencadangkan atau mengirim file.';

  @override
  String get privacyReadsTitle => 'Apa yang dibaca ExactSize';

  @override
  String get privacyReads =>
      'ExactSize hanya membuka foto yang Anda pilih. ExactSize tidak menelusuri galeri atau file Anda.';

  @override
  String get presetChooseForm => 'Pilih formulir';

  @override
  String presetApplied(String form, String kind) {
    return '$form · $kind';
  }

  @override
  String get presetKindPhoto => 'Foto';

  @override
  String get presetKindSignature => 'Tanda tangan';

  @override
  String presetSpecRange(String pixels, String size, String format) {
    return '$pixels · $size · $format';
  }

  @override
  String presetSpecUpTo(String pixels, String max, String format) {
    return '$pixels · hingga $max · $format';
  }

  @override
  String get presetListTitle => 'Formulir';

  @override
  String get presetSearchHint => 'Cari formulir';

  @override
  String get presetNoMatch => 'Tidak ada formulir yang cocok.';

  @override
  String get presetEnterYourself =>
      'Masukkan sendiri lebar, tinggi, dan ukuran file';

  @override
  String presetNoteDpi(String dpi) {
    return 'Formulir ini juga meminta $dpi DPI. ExactSize tidak menetapkan DPI.';
  }

  @override
  String get presetNoteBackground =>
      'Formulir ini juga memiliki aturan tentang latar belakang. ExactSize tidak mengubah latar belakang.';

  @override
  String get presetNoteContent =>
      'Formulir ini juga memiliki aturan lain untuk gambar ini. ExactSize tidak memeriksa aturan tersebut.';

  @override
  String get presetNotAffiliated =>
      'ExactSize tidak berafiliasi dengan organisasi dalam daftar ini.';

  @override
  String get presetLoadFailed =>
      'Daftar formulir tidak dapat ditampilkan. Anda dapat memasukkan sendiri lebar, tinggi, dan ukuran file.';

  @override
  String presetCountry(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'BD': 'Bangladesh',
      'FR': 'Prancis',
      'IN': 'India',
      'MX': 'Meksiko',
      'PK': 'Pakistan',
      'SG': 'Singapura',
      'US': 'Amerika Serikat',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String presetCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'job': 'Pekerjaan',
      'exam_admission': 'Ujian dan penerimaan siswa',
      'visa_passport': 'Visa dan paspor',
      'other': 'Lainnya',
    });
    return '$_temp0';
  }

  @override
  String get presetAnyPixelSize => 'Dimensi tidak dicantumkan';

  @override
  String get presetKbOnlyNote =>
      'Formulir ini tidak mencantumkan dimensi piksel. Masukkan lebar dan tinggi, atau gunakan dimensi foto.';
}
