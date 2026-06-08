import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final _db = Supabase.instance.client;

  List<Map<String, dynamic>> _registros = [];
  List<Map<String, dynamic>> _animales = [];
  bool _isLoading = true;

  // Contadores para stat cards
  int get _totalVacunas =>
      _registros.where((r) => r['tipo'] == 'Vacunación').length;
  int get _totalTratamientos =>
      _registros.where((r) => r['tipo'] == 'Tratamiento').length;
  int get _proximosControles {
    final ahora = DateTime.now();
    final limite = ahora.add(const Duration(days: 7));
    return _registros.where((r) {
      final pc = r['proximo_control'];
      if (pc == null) return false;
      final fecha = DateTime.tryParse(pc);
      if (fecha == null) return false;
      return fecha.isAfter(ahora) && fecha.isBefore(limite);
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Cargar animales para el formulario
      final animalesData = await _db
          .from('animales')
          .select('id, id_animal, raza')
          .order('raza');
      _animales = List<Map<String, dynamic>>.from(animalesData);

      // Cargar registro_sanitario con datos del animal
      final data = await _db
          .from('registro_sanitario')
          .select(
            'id, tipo, fecha, observaciones, proximo_control, id_animal, animales(raza, id_animal)',
          )
          .order('created_at', ascending: false);

      _registros = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _mostrarError('Error al cargar datos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static String _fmtFecha(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  String _nombreAnimal(Map<String, dynamic> r) {
    final animal = r['animales'];
    if (animal == null) return '—';
    final id = animal['id_animal'];
    final raza = animal['raza'] ?? '—';
    return id != null ? '$raza ($id)' : raza;
  }

  @override
  Widget build(BuildContext context) {
    // Próximos controles en los próximos 7 días
    final ahora = DateTime.now();
    final limite = ahora.add(const Duration(days: 7));
    final proximosList = _registros.where((r) {
      final pc = r['proximo_control'];
      if (pc == null) return false;
      final fecha = DateTime.tryParse(pc);
      if (fecha == null) return false;
      return fecha.isAfter(ahora) && fecha.isBefore(limite);
    }).toList();

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Encabezado (responsive) ───────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control Sanitario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestión de vacunas y tratamientos',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _mostrarFormulario,
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo Registro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Stat cards (responsive) ────────────────────
                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      icon: Icons.vaccines,
                      iconColor: AppColors.green,
                      label: 'Total Vacunas',
                      value: '$_totalVacunas',
                    ),
                    _StatCard(
                      icon: Icons.medical_services,
                      iconColor: Colors.blue,
                      label: 'Tratamientos',
                      value: '$_totalTratamientos',
                    ),
                    _StatCard(
                      icon: Icons.warning_amber,
                      iconColor: const Color(0xFF9A6A00),
                      label: 'Próximos',
                      value: '$_proximosControles',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Banner próximos controles ────────────────────
                if (proximosList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF3DC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7D5A0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: Color(0xFF9A6A00),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Controles Próximos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9A6A00),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hay ${proximosList.length} vacunacion${proximosList.length != 1 ? 'es' : ''} programada${proximosList.length != 1 ? 's' : ''} para los próximos 7 días',
                                style: const TextStyle(
                                  color: Color(0xFF9A6A00),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Tabla historial ─────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Historial Sanitario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: AppColors.green,
                              ),
                              onPressed: _cargarDatos,
                              tooltip: 'Actualizar',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      _registros.isEmpty
                          ? _emptyState()
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Animal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Observaciones',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Fecha',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Próximo Control',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Acciones',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: _registros.map((r) {
                                  final pc = r['proximo_control'];
                                  final vencido =
                                      pc != null &&
                                      DateTime.tryParse(
                                            pc,
                                          )?.isBefore(DateTime.now()) ==
                                          true;

                                  return DataRow(
                                    cells: [
                                      // Tipo
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: r['tipo'] == 'Vacunación'
                                                ? AppColors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.blue.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            r['tipo'] ?? '—',
                                            style: TextStyle(
                                              color: r['tipo'] == 'Vacunación'
                                                  ? AppColors.green
                                                  : Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Animal
                                      DataCell(Text(_nombreAnimal(r))),
                                      // Observaciones
                                      DataCell(
                                        SizedBox(
                                          width: 160,
                                          child: Text(
                                            r['observaciones'] ?? '—',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // Fecha
                                      DataCell(
                                        Text(_fmtFecha(r['fecha'] ?? '')),
                                      ),
                                      // Próximo control
                                      DataCell(
                                        pc != null
                                            ? Text(
                                                _fmtFecha(pc),
                                                style: TextStyle(
                                                  color: vencido
                                                      ? Colors.red
                                                      : Colors.orange.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : const Text('—'),
                                      ),
                                      // Acciones
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: AppColors.blue,
                                              ),
                                              tooltip: 'Editar',
                                              onPressed: () =>
                                                  _mostrarFormulario(
                                                    registro: r,
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              tooltip: 'Eliminar',
                                              onPressed: () =>
                                                  _confirmarEliminar(r),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No hay registros sanitarios',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formulario ────────────────────────────────────────────────────────────
  void _mostrarFormulario({Map<String, dynamic>? registro}) {
    final esEdicion = registro != null;
    String tipo = registro?['tipo'] ?? 'Vacunación';
    String? idAnimalVal = registro?['id_animal'];
    final obsCtrl = TextEditingController(
      text: registro?['observaciones'] ?? '',
    );
    DateTime fecha = registro?['fecha'] != null
        ? DateTime.tryParse(registro!['fecha']) ?? DateTime.now()
        : DateTime.now();
    DateTime? proximoControl = registro?['proximo_control'] != null
        ? DateTime.tryParse(registro!['proximo_control'])
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                esEdicion ? Icons.edit : Icons.add_circle,
                color: AppColors.green,
              ),
              const SizedBox(width: 8),
              Text(esEdicion ? 'Editar Registro' : 'Nuevo Registro Sanitario'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tipo
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Vacunación',
                        child: Text('Vacunación'),
                      ),
                      DropdownMenuItem(
                        value: 'Tratamiento',
                        child: Text('Tratamiento'),
                      ),
                    ],
                    onChanged: (v) => setModal(() => tipo = v!),
                  ),
                  const SizedBox(height: 14),

                  // Animal
                  DropdownButtonFormField<String>(
                    initialValue: idAnimalVal,
                    decoration: InputDecoration(
                      labelText: 'Animal *',
                      prefixIcon: const Icon(Icons.agriculture),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: _animales.map((a) {
                      final label = a['id_animal'] != null
                          ? '${a['raza']} (${a['id_animal']})'
                          : a['raza'] as String;
                      return DropdownMenuItem(
                        value: a['id'] as String,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (v) => setModal(() => idAnimalVal = v),
                  ),
                  const SizedBox(height: 14),

                  // Observaciones
                  TextField(
                    controller: obsCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Observaciones',
                      hintText: 'Ej: Fiebre Aftosa, dosis 5ml...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fecha
                  _DatePicker(
                    label: 'Fecha *',
                    icon: Icons.event,
                    value: fecha,
                    onPicked: (d) => setModal(() => fecha = d),
                  ),
                  const SizedBox(height: 14),

                  // Próximo control
                  _DatePicker(
                    label: 'Próximo Control (opcional)',
                    icon: Icons.event_repeat,
                    value: proximoControl,
                    onPicked: (d) => setModal(() => proximoControl = d),
                    nullable: true,
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
              onPressed: idAnimalVal == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _guardar(
                        id: registro?['id'],
                        tipo: tipo,
                        idAnimal: idAnimalVal!,
                        observaciones: obsCtrl.text.trim().isEmpty
                            ? null
                            : obsCtrl.text.trim(),
                        fecha: fecha,
                        proximoControl: proximoControl,
                        esEdicion: esEdicion,
                      );
                    },
              child: Text(esEdicion ? 'Guardar cambios' : 'Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar({
    String? id,
    required String tipo,
    required String idAnimal,
    String? observaciones,
    required DateTime fecha,
    DateTime? proximoControl,
    required bool esEdicion,
  }) async {
    try {
      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final data = {
        'tipo': tipo,
        'id_animal': idAnimal,
        'observaciones': observaciones,
        'fecha': fmt(fecha),
        'proximo_control': proximoControl != null ? fmt(proximoControl) : null,
      };

      if (esEdicion && id != null) {
        await _db.from('registro_sanitario').update(data).eq('id', id);
      } else {
        await _db.from('registro_sanitario').insert(data);
      }

      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esEdicion ? 'Registro actualizado' : 'Registro guardado',
            ),
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

  void _confirmarEliminar(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar registro'),
          ],
        ),
        content: Text(
          '¿Eliminar el registro de ${r['tipo']} del ${_fmtFecha(r['fecha'] ?? '')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _db.from('registro_sanitario').delete().eq('id', r['id']);
                await _cargarDatos();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Registro eliminado'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                _mostrarError('Error al eliminar: $e');
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
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
}

// ── Widget auxiliar: DatePicker ───────────────────────────────────────────────
class _DatePicker extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final bool nullable;

  const _DatePicker({
    required this.label,
    required this.icon,
    required this.value,
    required this.onPicked,
    this.nullable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              value != null
                  ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
                  : label,
              style: TextStyle(
                color: value != null ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar: StatCard ─────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
