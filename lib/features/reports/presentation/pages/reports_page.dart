import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

// ── Modelos internos ──────────────────────────────────────────────────────────
class _LoteStat {
  final String nombre;
  final double pesoPromedio;
  final int animales;
  _LoteStat({
    required this.nombre,
    required this.pesoPromedio,
    required this.animales,
  });
}

class _RazaStat {
  final String raza;
  final int cantidad;
  _RazaStat({required this.raza, required this.cantidad});
}

class _SanitarioStat {
  final String tipo;
  final int cantidad;
  _SanitarioStat({required this.tipo, required this.cantidad});
}

// ─────────────────────────────────────────────────────────────────────────────
class _ReportsPageState extends State<ReportsPage> {
  final _db = Supabase.instance.client;

  int _selectedReport = 0; // 0=Peso  1=Sanitario  2=Inventario
  int _selectedPeriod = 1; // 0=Semana 1=Mes 2=Trimestre 3=Año

  static const _periods = ['Semana', 'Mes', 'Trimestre', 'Año'];

  // ── Datos cargados desde Supabase ─────────────────────────────────────────
  List<_LoteStat> _lotesStats = [];
  List<_RazaStat> _razaStats = [];
  List<_SanitarioStat> _sanitStats = [];

  /// Registros completos para la tabla "Actividad Sanitaria".
  /// Estructura esperada por fila (mapeo simple desde Supabase):
  /// {
  ///   tipo, observaciones, fecha, proximo_control?,
  ///   animales: { raza, id_animal }
  /// }
  List<Map<String, dynamic>> _sanitRegistros = [];

  int _totalAnimales = 0;
  int _totalControles = 0;
  double _pesoPromGlobal = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ── Fecha de corte según período ──────────────────────────────────────────
  DateTime get _fechaDesde {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0:
        return now.subtract(const Duration(days: 7));
      case 1:
        return now.subtract(const Duration(days: 30));
      case 2:
        return now.subtract(const Duration(days: 90));
      case 3:
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  String get _periodoLabel {
    switch (_selectedPeriod) {
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

  // ── Carga principal ───────────────────────────────────────────────────────
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final desde = _fechaDesde.toIso8601String().substring(0, 10);

      // ── Animales con su lote y pesos dentro del período ──────────────────
      final animData = await _db
          .from('animales')
          .select(
            'id, raza, id_lote, lotes(nombre), registro_peso(peso, fecha)',
          );

      final animales = animData as List;
      _totalAnimales = animales.length;

      // Peso promedio global (último peso de cada animal dentro del período)
      final Map<String, List<double>> pesosPorLote = {};
      final Map<String, String> nombrePorLote = {};
      final todosLosPesos = <double>[];

      for (final a in animales) {
        final idLote = a['id_lote'] as String?;
        final loteObj = a['lotes'];
        final nombreL = loteObj != null
            ? (loteObj['nombre'] as String? ?? 'Sin lote')
            : 'Sin lote';
        if (idLote != null) nombrePorLote[idLote] = nombreL;

        final pesos = (a['registro_peso'] as List?)
            ?.where((p) => (p['fecha'] as String).compareTo(desde) >= 0)
            .toList();
        if (pesos == null || pesos.isEmpty) continue;

        pesos.sort(
          (x, y) => (y['fecha'] as String).compareTo(x['fecha'] as String),
        );
        final ultimo = (pesos.first['peso'] as num).toDouble();
        todosLosPesos.add(ultimo);

        if (idLote != null) {
          pesosPorLote.putIfAbsent(idLote, () => []).add(ultimo);
        }
      }

      _pesoPromGlobal = todosLosPesos.isEmpty
          ? 0
          : todosLosPesos.reduce((a, b) => a + b) / todosLosPesos.length;

      // ── Stats por lote ────────────────────────────────────────────────────
      _lotesStats = pesosPorLote.entries.map((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        return _LoteStat(
          nombre: nombrePorLote[e.key] ?? e.key.substring(0, 6),
          pesoPromedio: avg,
          animales: e.value.length,
        );
      }).toList()..sort((a, b) => b.pesoPromedio.compareTo(a.pesoPromedio));

      // ── Distribución por raza ─────────────────────────────────────────────
      final Map<String, int> razaCount = {};
      for (final a in animales) {
        final raza = (a['raza'] as String?)?.trim() ?? 'Otra';
        razaCount[raza] = (razaCount[raza] ?? 0) + 1;
      }
      _razaStats =
          razaCount.entries
              .map((e) => _RazaStat(raza: e.key, cantidad: e.value))
              .toList()
            ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

      // ── Actividad sanitaria en el período ────────────────────────────────
      // Nota: usamos select con relación a animales para poder mostrar "Animal".
      // Si en tu schema el join se llama distinto, ajustaremos el alias luego.
      final sanitData = await _db
          .from('registro_sanitario')
          .select(
            'tipo, fecha, observaciones, proximo_control, id_animal, animales(raza, id_animal)',
          )
          .gte('fecha', desde)
          .order('fecha', ascending: false);

      _totalControles = (sanitData as List).length;
      _sanitRegistros = List<Map<String, dynamic>>.from(sanitData);

      final Map<String, int> sanitCount = {};
      for (final s in sanitData as List) {
        final tipo = (s['tipo'] as String?)?.trim() ?? 'Otro';
        sanitCount[tipo] = (sanitCount[tipo] ?? 0) + 1;
      }
      _sanitStats =
          sanitCount.entries
              .map((e) => _SanitarioStat(tipo: e.key, cantidad: e.value))
              .toList()
            ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reportes',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Análisis y estadísticas del ganado',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.green),
                  tooltip: 'Actualizar',
                  onPressed: _cargarDatos,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Selector de tipo de reporte ───────────────────────────────
            Row(
              children: [
                _reportCard(
                  index: 0,
                  title: 'Reporte de Peso',
                  subtitle: 'Peso promedio por lote',
                  icon: Icons.bar_chart,
                ),
                const SizedBox(width: 12),
                _reportCard(
                  index: 1,
                  title: 'Reporte Sanitario',
                  subtitle: 'Vacunas y tratamientos',
                  icon: Icons.medical_services_outlined,
                ),
                const SizedBox(width: 12),
                _reportCard(
                  index: 2,
                  title: 'Inventario General',
                  subtitle: 'Distribución por raza y lote',
                  icon: Icons.picture_as_pdf_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Selector de período ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _periodoLabel,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_periods.length, (i) {
                      final active = _selectedPeriod == i;
                      return Padding(
                        padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                        child: ChoiceChip(
                          label: Text(_periods[i]),
                          selected: active,
                          onSelected: (_) {
                            setState(() => _selectedPeriod = i);
                            _cargarDatos(); // ← recarga con el nuevo período
                          },
                          selectedColor: AppColors.green,
                          labelStyle: TextStyle(
                            color: active ? Colors.white : Colors.black87,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Contenido del reporte seleccionado ────────────────────────
            if (_isLoading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildReporteActual(),
              const SizedBox(height: 20),

              // ── Botones exportar ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Exportación a PDF próximamente disponible',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar a PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Exportación a Excel próximamente disponible',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Exportar a Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nota offline
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nota: Los reportes se pueden exportar cuando haya conexión a internet. '
                        'En modo offline, los datos se guardan localmente y se sincronizarán '
                        'automáticamente al conectarse.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ── Despacha al reporte correcto ──────────────────────────────────────────
  Widget _buildReporteActual() {
    switch (_selectedReport) {
      case 0:
        return _buildReportePeso();
      case 1:
        return _buildReporteSanitario();
      case 2:
        return _buildInventarioGeneral();
      default:
        return _buildReportePeso();
    }
  }

  // ── REPORTE DE PESO ───────────────────────────────────────────────────────
  Widget _buildReportePeso() {
    if (_lotesStats.isEmpty) {
      return _emptyState(
        icon: Icons.bar_chart,
        msg: 'Sin datos de peso para el período seleccionado',
        sub: 'Registra pesos en animales asociados a un lote',
      );
    }

    final maxY =
        (_lotesStats
                    .map((e) => e.pesoPromedio)
                    .reduce((a, b) => a > b ? a : b) *
                1.3)
            .ceilToDouble();

    return Column(
      children: [
        // Gráfica de barras
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Peso Promedio por Lote',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Text(
                'Peso (kg)',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barGroups: _lotesStats
                        .asMap()
                        .entries
                        .map(
                          (e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.pesoPromedio,
                                color: AppColors.green,
                                width: 48,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= _lotesStats.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _lotesStats[i].nombre,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: maxY / 4,
                          reservedSize: 36,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tarjetas por lote
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _lotesStats.asMap().entries.map((e) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: e.key < _lotesStats.length - 1 ? 12 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.value.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${e.value.pesoPromedio.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e.value.animales} animales',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── REPORTE SANITARIO ─────────────────────────────────────────────────────
  Widget _buildReporteSanitario() {
    return Column(
      children: [
        // Resumen
        Row(
          children: [
            Expanded(
              child: _statTile(
                'Total controles',
                '$_totalControles',
                Icons.medical_services,
                AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                'Tipos distintos',
                '${_sanitStats.length}',
                Icons.category_outlined,
                AppColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Barras por tipo
        if (_sanitStats.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Controles por tipo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ..._sanitStats.map((s) {
                  final pct = _totalControles > 0
                      ? s.cantidad / _totalControles
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.tipo,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${s.cantidad} (${(pct * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          )
        else
          _emptyState(
            icon: Icons.medical_services_outlined,
            msg: 'Sin controles sanitarios en el período',
            sub: 'Registra controles desde "Control sanitario"',
          ),

        const SizedBox(height: 16),

        // Tabla Actividad Sanitaria
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Actividad Sanitaria',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const Divider(height: 1),
              _sanitRegistros.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No hay registros sanitarios para el período seleccionado',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade50,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Tipo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Animal',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Descripción',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Fecha',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: _sanitRegistros.map((r) {
                          final tipo = (r['tipo'] as String?)?.trim() ?? '—';
                          final obs = (r['observaciones'] as String?)?.trim();
                          final fechaRaw = (r['fecha'] as String?)?.trim();
                          final fecha = fechaRaw == null || fechaRaw.isEmpty
                              ? null
                              : fechaRaw;

                          final animalesObj = r['animales'];
                          final raza = animalesObj is Map
                              ? (animalesObj['raza'] as String?)
                              : null;
                          final idAnimal =
                              r['id_animal'] ??
                              (animalesObj is Map ? animalesObj['id'] : null);

                          final nombreAnimal =
                              (raza ?? '').toString().isNotEmpty
                              ? '${raza ?? '—'}${idAnimal != null ? ' (${idAnimal.toString()})' : ''}'
                              : (idAnimal != null
                                    ? '— (${idAnimal.toString()})'
                                    : '—');

                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tipo == 'Vacunación'
                                        ? AppColors.green.withValues(alpha: 0.1)
                                        : AppColors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tipo,
                                    style: TextStyle(
                                      color: tipo == 'Vacunación'
                                          ? AppColors.green
                                          : AppColors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(nombreAnimal)),
                              DataCell(
                                SizedBox(
                                  width: 220,
                                  child: Text(
                                    obs ?? '—',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(fecha == null ? '—' : _fmtFecha(fecha)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ],
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  // ── INVENTARIO GENERAL ────────────────────────────────────────────────────
  Widget _buildInventarioGeneral() {
    final colors = [
      AppColors.green,
      AppColors.blue,
      AppColors.brown,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return Column(
      children: [
        // Resumen
        Row(
          children: [
            Expanded(
              child: _statTile(
                'Total animales',
                '$_totalAnimales',
                Icons.agriculture,
                AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                'Lotes activos',
                '${_lotesStats.length}',
                Icons.grid_view,
                AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statTile(
                'Peso prom. global',
                _pesoPromGlobal > 0
                    ? '${_pesoPromGlobal.toStringAsFixed(1)} kg'
                    : '— kg',
                Icons.monitor_weight,
                AppColors.brown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_razaStats.isEmpty)
          _emptyState(
            icon: Icons.agriculture,
            msg: 'Sin animales registrados',
            sub: 'Registra animales desde "Registro de Animales"',
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pie chart
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Distribución por Raza',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _razaStats.asMap().entries.map((e) {
                              final color = colors[e.key % colors.length];
                              final pct = _totalAnimales > 0
                                  ? e.value.cantidad / _totalAnimales * 100
                                  : 0.0;
                              return PieChartSectionData(
                                value: e.value.cantidad.toDouble(),
                                color: color,
                                title:
                                    '${e.value.raza}\n${pct.toStringAsFixed(0)}%',
                                titleStyle: TextStyle(
                                  fontSize: 10,
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                                titlePositionPercentageOffset: 1.4,
                                radius: 70,
                              );
                            }).toList(),
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Lista por raza
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Animales por Raza',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._razaStats.asMap().entries.map((e) {
                        final color = colors[e.key % colors.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.value.raza,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                '${e.value.cantidad} animal${e.value.cantidad != 1 ? 'es' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static String _fmtFecha(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String msg,
    required String sub,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _reportCard({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final active = _selectedReport == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedReport = index),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: active ? AppColors.green : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.green : const Color(0xFFE6E6E6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppColors.green,
                size: 28,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
