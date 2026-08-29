import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

class FileDownloadHelper {
  static void downloadCsv({required String csvContent, required String filename}) {
    downloadCsvImpl(csvContent: csvContent, filename: filename);
  }
}
