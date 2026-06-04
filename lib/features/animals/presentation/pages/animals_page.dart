import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';

class AnimalsPage extends StatefulWidget {
  const AnimalsPage({super.key});

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

// ── Modelo local ─────────────────────────────────────
class _Animal {
  final String id;
  final String raza;
  final String sexo;
  final String? fechaNacimiento;
  final String? idLote;
  final String? nombreLote;
  final double? ultimoPeso;

  _Animal({
    required this.id,
    required this.raza,
    required this.sexo,
    this.fechaNacimiento,
    this.idLote,
    this.nombreLote,
    this.ultimoPeso,
  });

  String get edad {
    if (fechaNacimiento == null) return '—';
    final nac = DateTime.tryParse(fechaNacimiento!);
    if (nac == null) return '—';
    final diff = DateTime.now().difference(nac);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    if (years > 0) return '$years año${years > 1 ? 's' : ''}';
    return '$months mes${months != 1 ? 'es' : ''}';
  }
}

class _AnimalsPageState extends State<AnimalsPage> {
  final _db = Supabase.instance.client;
  List<_Animal> _animales = [];
  List<_Animal> _filtrados = [];
  List<Map<String, dynamic>> _lotes = [];
  bool _isLoading = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      // Cargar lotes para el formulario
      final lotesData = await _db
          .from('lotes')
          .select('id, nombre')
          .order('nombre');
      _lotes = List<Map<String, dynamic>>.from(lotesData);

      // Cargar animales con su lote y último peso
      final data = await _db
          .from('animales')
          .select('''
            id, raza, sexo, fecha_nacimiento, id_lote,
            lotes(nombre),
            registro_peso(peso, fecha)
          ''')
          .order('created_at', ascending: false);

      _animales = (data as List).map((item) {
        // Obtener último peso
        double? ultimoPeso;
        final pesos = item['registro_peso'] as List?;
        if (pesos != null && pesos.isNotEmpty) {
          pesos.sort(
            (a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String),
          );
          ultimoPeso = (pesos.first['peso'] as num).toDouble();
        }

        return _Animal(
          id: item['id'],
          raza: item['raza'] ?? '—',
          sexo: item['sexo'] ?? '—',
          fechaNacimiento: item['fecha_nacimiento'],
          idLote: item['id_lote'],
          nombreLote: item['lotes']?['nombre'],
          ultimoPeso: ultimoPeso,
        );
      }).toList();

      _filtrados = List.from(_animales);
    } catch (e) {
      _mostrarError('Error al cargar animales: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar(String query) {
    setState(() {
      _busqueda = query;
      _filtrados = _animales.where((a) {
        final q = query.toLowerCase();
        return a.raza.toLowerCase().contains(q) ||
            (a.nombreLote?.toLowerCase().contains(q) ?? false) ||
            a.sexo.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registro de Animales',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  Text(
                    'Gestione el inventario bovino',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.green),
                    onPressed: _cargarDatos,
                    tooltip: 'Actualizar',
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo Animal'),
                    onPressed: () => _mostrarFormulario(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Buscador ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: _filtrar,
            decoration: InputDecoration(
              hintText: 'Buscar por raza, lote o sexo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busqueda.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _filtrar('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Contenido ──
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtrados.isEmpty
              ? _emptyState()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_filtrados.length} animal${_filtrados.length != 1 ? 'es' : ''}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                AppColors.greenLight,
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Raza',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Sexo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Edad',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Lote',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Peso',
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
                              rows: _filtrados.map((a) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(a.raza)),
                                    DataCell(_sexoBadge(a.sexo)),
                                    DataCell(Text(a.edad)),
                                    DataCell(Text(a.nombreLote ?? '—')),
                                    DataCell(
                                      Text(
                                        a.ultimoPeso != null
                                            ? '${a.ultimoPeso!.toStringAsFixed(1)} kg'
                                            : '—',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.green,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: AppColors.blue,
                                            ),
                                            onPressed: () =>
                                                _mostrarFormulario(animal: a),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            onPressed: () =>
                                                _confirmarEliminar(a),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _sexoBadge(String sexo) {
    final isMacho = sexo == 'Macho';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isMacho ? const Color(0xFFE6F1FB) : const Color(0xFFFCEBF9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        sexo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isMacho ? const Color(0xFF185FA5) : const Color(0xFF8B0066),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, size: 48, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          Text(
            _busqueda.isNotEmpty
                ? 'No se encontraron resultados'
                : 'No hay animales registrados',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _busqueda.isNotEmpty
                ? 'Intenta con otro término de búsqueda'
                : 'Registra tu primer animal',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (_busqueda.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Registrar animal'),
              onPressed: () => _mostrarFormulario(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Formulario ───────────────────────────────────
  void _mostrarFormulario({_Animal? animal}) {
    final razaCtrl = TextEditingController(text: animal?.raza ?? '');
    String sexo = animal?.sexo ?? 'Macho';
    String? idLote = animal?.idLote;
    DateTime? fechaNac = animal?.fechaNacimiento != null
        ? DateTime.tryParse(animal!.fechaNacimiento!)
        : null;
    final formKey = GlobalKey<FormState>();
    final esEdicion = animal != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
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
              Text(esEdicion ? 'Editar Animal' : 'Nuevo Animal'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Raza
                  TextFormField(
                    controller: razaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Raza *',
                      hintText: 'Ej: Brahman, Cebu, Angus',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (v) =>
                        v!.trim().isEmpty ? 'La raza es obligatoria' : null,
                  ),
                  const SizedBox(height: 14),

                  // Sexo
                  DropdownButtonFormField<String>(
                    value: sexo,
                    decoration: InputDecoration(
                      labelText: 'Sexo *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                      DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
                    ],
                    onChanged: (v) => setModalState(() => sexo = v!),
                  ),
                  const SizedBox(height: 14),

                  // Lote
                  DropdownButtonFormField<String>(
                    value: idLote,
                    decoration: InputDecoration(
                      labelText: 'Lote',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin lote'),
                      ),
                      ..._lotes.map(
                        (l) => DropdownMenuItem(
                          value: l['id'] as String,
                          child: Text(l['nombre'] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => idLote = v),
                  ),
                  const SizedBox(height: 14),

                  // Fecha nacimiento
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: fechaNac ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => fechaNac = picked);
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
                            fechaNac != null
                                ? '${fechaNac!.day}/${fechaNac!.month}/${fechaNac!.year}'
                                : 'Fecha de nacimiento',
                            style: TextStyle(
                              color: fechaNac != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
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
                await _guardarAnimal(
                  id: animal?.id,
                  raza: razaCtrl.text.trim(),
                  sexo: sexo,
                  idLote: idLote,
                  fechaNac: fechaNac,
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

  Future<void> _guardarAnimal({
    String? id,
    required String raza,
    required String sexo,
    String? idLote,
    DateTime? fechaNac,
    required bool esEdicion,
  }) async {
    try {
      final data = {
        'raza': raza,
        'sexo': sexo,
        if (idLote != null) 'id_lote': idLote,
        if (fechaNac != null)
          'fecha_nacimiento':
              '${fechaNac.year}-${fechaNac.month.toString().padLeft(2, '0')}-${fechaNac.day.toString().padLeft(2, '0')}',
      };

      if (esEdicion && id != null) {
        await _db.from('animales').update(data).eq('id', id);
      } else {
        await _db.from('animales').insert(data);
      }

      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esEdicion ? 'Animal actualizado' : 'Animal registrado',
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

  void _confirmarEliminar(_Animal animal) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar animal'),
          ],
        ),
        content: Text(
          '¿Eliminar ${animal.raza} (${animal.sexo})?\n'
          'Se borrarán también sus registros de peso y sanitarios.',
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
                await _db.from('animales').delete().eq('id', animal.id);
                await _cargarDatos();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Animal eliminado'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
