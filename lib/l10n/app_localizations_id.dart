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
      'Foto Anda tetap di ponsel Anda dan tidak pernah diunggah ke internet.';

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
  String get exportSave => 'Save';

  @override
  String get exportShare => 'Share';

  @override
  String get exportSaveAs => 'Choose where to save';

  @override
  String get exportOpen => 'Open';

  @override
  String get exportDone => 'Done';

  @override
  String exportReady(String width, String height, String size, String format) {
    return 'Ready: $width × $height px, $size, $format';
  }

  @override
  String exportSaved(String folder, String fileName) {
    return 'Saved to $folder as $fileName.';
  }

  @override
  String exportSavedAs(String fileName) {
    return 'Saved as $fileName.';
  }

  @override
  String exportAlreadySaved(String fileName, String folder) {
    return 'Already saved as $fileName in $folder.';
  }

  @override
  String exportAlreadySavedAs(String fileName) {
    return 'Already saved as $fileName.';
  }

  @override
  String get exportNoSpace =>
      'There isn\'t enough free space on this phone to save the file. Free some space and try again.';

  @override
  String get exportSaveFailed =>
      'Couldn\'t save the file. Try again, or share it instead.';

  @override
  String get exportPermissionDenied =>
      'ExactSize needs the Storage permission to save to your gallery. Turn it on in Settings. You can also share the file or choose where to save it.';

  @override
  String get exportFileMissing =>
      'The new file is no longer available. Your gallery photos stay as they are. Choose the photo again to make a new one.';

  @override
  String get exportShareFailed =>
      'Couldn\'t open the share menu. Try again, or save the file instead.';

  @override
  String get exportNoViewer =>
      'No app on this phone can open this file. You can still share it.';

  @override
  String get exportPrivacy =>
      'Saving puts a copy in your gallery or a folder you pick. Sharing gives a copy to the app you choose.';

  @override
  String get exportShareHint =>
      'Some chat apps shrink photos. For a form, save the file and choose it in the upload window.';

  @override
  String get exportLeaveTitle => 'Leave without saving?';

  @override
  String get exportLeaveBody =>
      'The new file will be deleted. Your gallery photos stay as they are.';

  @override
  String get exportStay => 'Stay';

  @override
  String get exportLeave => 'Leave';

  @override
  String get exportSaving => 'Saving…';
}
