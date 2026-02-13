// // TODO Implement this library.import 'dart:typed_data';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:path_provider/path_provider.dart';

// class PlatformDownloader {
//   static Future<String> saveTempPdf(Uint8List bytes, String name) async {
//     final dir = await getTemporaryDirectory();
//     final path = '${dir.path}/$name';
//     final file = File(path);
//     await file.writeAsBytes(bytes);
//     return path;
//   }
// }
