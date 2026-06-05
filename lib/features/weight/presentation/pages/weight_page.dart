import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _RegistroPeso {
  final String id;
  final String animalId;
  final String animalLabel; // raza + id_animal
  final double peso;
  final String fecha;
  final double? cambio;

  _RegistroPeso({
    required this.id,
    required this.animalId,
    required this.animalLabel,
    required this.peso,
    required this.fecha,
    this.cambio,
  });
}

class _Animal {
  final String id;
  final String label;
  _Animal({required this.id, required this.label});
}

class _WeightPageState extends State<WeightPage> {
  final _db = Supabase.instance.client;

  List<_RegistroPeso> _registros = [];
  List<_Animal> _animales = [];
  String? _animalSeleccionado; // id del animal para la gráfica
  bool _isLoading = true;

  // Spots de la gráfica
  List<FlSpot> _spots = [];
  double _maxY = 600;
  List<String> _fechaLabels = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ── Carga principal ───────────────────────────────────────────────────────
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Animales disponibles
      final animData = await _db
          .from('animales')
          .select('id, id_animal, raza')
          .order('raza');
      _animales = (animData as List).map((a) {
        final idAnim = a['id_animal'] as String?;
        final raza = a['raza'] as String? ?? 'Animal';
        final label = idAnim != null ? '$raza ($idAnim)' : raza;
        return _Animal(id: a['id'] as String, label: label);
      }).toList();

      // Si no hay animal seleccionado, usar el primero
      if (_animales.isNotEmpty && _animalSeleccionado == null) {
        _animalSeleccionado = _animales.first.id;
      }

      // Todos los registros de peso recientes (últimos 20)
      final pesosData = await _db
          .from('registro_peso')
          .select('id, id_animal, peso, fecha, animales(raza, id_animal)')
          .order('fecha', ascending: false)
          .limit(20);

      // Calcular cambio respecto al registro anterior del mismo animal
      final Map<String, double> ultimoPorAnimal = {};
      final List<_RegistroPeso> registros = [];

      // Ordenar asc para calcular cambio, luego revertir
      final pesosAsc = List.from(
        pesosData,
      )..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));

      for (final p in pesosAsc) {
        final animalId = p['id_animal'] as String;
        final peso = (p['peso'] as num).toDouble();
        final animal = p['animales'];
        final raza = animal != null
            ? (animal['raza'] as String? ?? 'Animal')
            : 'Animal';
        final idAnim = animal != null ? (animal['id_animal'] as String?) : null;
        final label = idAnim != null ? '$raza ($idAnim)' : raza;

        final cambio = ultimoPorAnimal.containsKey(animalId)
            ? peso - ultimoPorAnimal[animalId]!
            : null;
        ultimoPorAnimal[animalId] = peso;

        registros.add(
          _RegistroPeso(
            id: p['id'] as String,
            animalId: animalId,
            animalLabel: label,
            peso: peso,
            fecha: p['fecha'] as String,
            cambio: cambio,
          ),
        );
      }

      // Invertir para mostrar más recientes primero
      _registros = registros.reversed.toList();

      // Cargar gráfica del animal seleccionado
      await _cargarGrafica();

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar: $e');
      }
    }
  }

  Future<void> _cargarGrafica() async {
    if (_animalSeleccionado == null) {
      _spots = [];
      return;
    }
    final data = await _db
        .from('registro_peso')
        .select('peso, fecha')
        .eq('id_animal', _animalSeleccionado!)
        .order('fecha', ascending: true);

    if ((data as List).isEmpty) {
      _spots = [];
      _fechaLabels = [];
      return;
    }

    _fechaLabels = data.map((d) => _fmtFecha(d['fecha'] as String)).toList();
    _spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['peso'] as num).toDouble());
    }).toList();

    final pesos = data.map((d) => (d['peso'] as num).toDouble());
    _maxY = (pesos.reduce((a, b) => a > b ? a : b) * 1.3).ceilToDouble();
    if (_maxY < 100) _maxY = 600;
  }

  String _fmtFecha(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}' : iso;
  }

  // ── Formulario registro de peso ───────────────────────────────────────────
  void _mostrarFormulario() {
    if (_animales.isEmpty) {
      _mostrarError('Primero debes registrar animales');
      return;
    }

    String animalId = _animales.first.id;
    final pesoCtrl = TextEditingController();
    DateTime fecha = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Text('Registrar Peso'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animal
                  DropdownButtonFormField<String>(
                    initialValue: animalId,
                    decoration: InputDecoration(
                      labelText: 'Animal *',
                      prefixIcon: const Icon(Icons.pets_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: _animales
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => animalId = v!),
                  ),
                  const SizedBox(height: 14),

                  // Peso
                  TextFormField(
                    controller: pesoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Peso (kg) *',
                      hintText: 'Ej: 350.5',
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      suffixText: 'kg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El peso es obligatorio';
                      }
                      final p = double.tryParse(v.trim().replaceAll(',', '.'));
                      if (p == null || p <= 0) {
                        return 'Ingresa un peso válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Fecha
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fecha,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => fecha = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const Spacer(),
                          const Text(
                            'Fecha del pesaje',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _guardarPeso(
                  animalId: animalId,
                  peso: double.parse(pesoCtrl.text.trim().replaceAll(',', '.')),
                  fecha: fecha,
                );
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPeso({
    required String animalId,
    required double peso,
    required DateTime fecha,
  }) async {
    try {
      final fechaStr =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      await _db.from('registro_peso').insert({
        'id_animal': animalId,
        'peso': peso,
        'fecha': fechaStr,
      });
      // Si este animal está seleccionado en la gráfica, actualizarla
      if (_animalSeleccionado == animalId) {
        await _cargarGrafica();
      }
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Peso registrado correctamente'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registro de Peso',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Control de peso del ganado',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.green),
                      tooltip: 'Actualizar',
                      onPressed: _cargarDatos,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _mostrarFormulario,
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar Peso'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // ── Gráfica evolución ──────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Evolución de Peso',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        // Selector de animal
                        if (_animales.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _animalSeleccionado,
                              underline: const SizedBox(),
                              isDense: true,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              items: _animales
                                  .map(
                                    (a) => DropdownMenuItem(
                                      value: a.id,
                                      child: Text(
                                        a.label,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) async {
                                setState(() => _animalSeleccionado = v);
                                await _cargarGrafica();
                                setState(() {});
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _spots.isEmpty
                          ? const Center(
                              child: Text(
                                'Sin registros de peso para este animal',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: _maxY,
                                gridData: const FlGridData(
                                  drawVerticalLine: false,
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: _maxY / 4,
                                      reservedSize: 36,
                                      getTitlesWidget: (v, _) => Text(
                                        v.toInt().toString(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: (_spots.length > 6
                                          ? (_spots.length / 4).ceilToDouble()
                                          : 1),
                                      getTitlesWidget: (v, _) {
                                        final i = v.toInt();
                                        if (i < 0 || i >= _fechaLabels.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          _fechaLabels[i],
                                          style: const TextStyle(fontSize: 9),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _spots,
                                    isCurved: true,
                                    color: AppColors.green,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: AppColors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Tabla registros recientes ──────────────────
              const Text(
                'Registros Recientes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _registros.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Sin registros de peso',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Cabecera
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Animal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Fecha',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Peso',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Cambio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Filas
                          ..._registros.map((r) {
                            Color changeColor = Colors.grey;
                            IconData? changeIcon;
                            String cambioStr = '—';
                            if (r.cambio != null) {
                              cambioStr =
                                  '${r.cambio! >= 0 ? '+' : ''}${r.cambio!.toStringAsFixed(1)} kg';
                              if (r.cambio! > 0) {
                                changeColor = AppColors.green;
                                changeIcon = Icons.trending_up;
                              } else if (r.cambio! < 0) {
                                changeColor = Colors.red;
                                changeIcon = Icons.trending_down;
                              }
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      r.animalLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _fmtFecha(r.fecha),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${r.peso.toStringAsFixed(1)} kg',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (changeIcon != null)
                                          Icon(
                                            changeIcon,
                                            size: 14,
                                            color: changeColor,
                                          ),
                                        const SizedBox(width: 2),
                                        Text(
                                          cambioStr,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: changeColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
