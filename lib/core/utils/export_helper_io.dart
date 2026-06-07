import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> descargarPDF(List<int> bytes, String nombre) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$nombre');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}

Future<void> descargarExcel(List<int> bytes, String nombre) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$nombre');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}