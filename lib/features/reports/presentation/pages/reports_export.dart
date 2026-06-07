// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:typed_data';

// NOTE: este archivo mantiene una exportación funcional mínima.

import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/export_helper.dart';

/// Nota: este archivo solo contiene lógica de exportación.
/// Se usa desde `ReportsPage`.

Future<void> _exportarPDF_impl({
  required SupabaseClient db,

  required int selectedReport,
  required int selectedPeriod,
  required DateTime fechaDesde,
}) async {
  final String periodoLabel = _periodoLabel(selectedPeriod);

  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Ganadería - Reportes',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Período: $periodoLabel'),
            pw.SizedBox(height: 16),
            pw.Text(
              'Tipo de reporte:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(_reporteLabel(selectedReport)),
            pw.SizedBox(height: 18),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Text('Generación básica de exportación (PDF).'),
          ],
        );
      },
    ),
  );

  final bytes = await doc.save();

  final pdfBytes = bytes is Uint8List ? bytes.toList() : (bytes as List<int>);

  await descargarPDF(
    pdfBytes,
    'reporte_${_reporteSlug(selectedReport)}_${_slugFecha(fechaDesde)}.pdf',
  );
}

Future<void> _exportarExcel_impl({
  // Temporal workaround: evitar errores de tipado del paquete excel.

  // ignore: invalid_use_of_visible_for_file_directive
  required SupabaseClient db,
  required int selectedReport,
  required int selectedPeriod,
  required DateTime fechaDesde,
}) async {
  final periodoLabel = _periodoLabel(selectedPeriod);

  final excel = xl.Excel.createExcel();
  final sheet = excel['Reporte'];

  // NOTE: excel.encode() consume datos typed dinámicamente.
  // Aquí usamos appendRow con valores simples para evitar errores de tipado.
  sheet.appendRow([xl.TextCellValue('Ganadería - Reportes')]);
  sheet.appendRow([
    xl.TextCellValue('Período'),
    xl.TextCellValue(periodoLabel),
  ]);
  // Evitamos excel CellValue tipado usando rows como lista dinámica.
  sheet.appendRow(<xl.CellValue?>[
    xl.TextCellValue('Tipo'),
    xl.TextCellValue(_reporteLabel(selectedReport)),
  ]);
  sheet.appendRow([]);
  sheet.appendRow([
    xl.TextCellValue('Detalle'),
    xl.TextCellValue('Generación básica de exportación (Excel).'),
  ]);

  final String fileName =
      'reporte_${_reporteSlug(selectedReport)}_${_slugFecha(fechaDesde)}.xlsx';

  final bytes = excel.encode();
  await descargarExcel(bytes!, fileName);
}

String _reporteLabel(int selectedReport) {
  switch (selectedReport) {
    case 0:
      return 'Reporte de Peso';
    case 1:
      return 'Reporte Sanitario';
    case 2:
      return 'Inventario General';
    default:
      return 'Reporte';
  }
}

String _reporteSlug(int selectedReport) {
  switch (selectedReport) {
    case 0:
      return 'peso';
    case 1:
      return 'sanitario';
    case 2:
      return 'inventario';
    default:
      return 'reporte';
  }
}

String _periodoLabel(int selectedPeriod) {
  switch (selectedPeriod) {
    case 0:
      return 'Últimos 7 días';
    case 1:
      return 'Últimos 30 días';
    case 2:
      return 'Últimos 3 meses';
    case 3:
      return 'Último año';
    default:
      return 'Últimos 30 días';
  }
}

String _slugFecha(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '${y}${m}${d}';
}
