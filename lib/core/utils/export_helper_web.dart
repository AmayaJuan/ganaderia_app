import 'dart:html' as html;
import 'dart:typed_data';

Future<void> descargarPDF(List<int> bytes, String nombre) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> descargarExcel(List<int> bytes, String nombre) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', nombre)
    ..click();
  html.Url.revokeObjectUrl(url);
}
