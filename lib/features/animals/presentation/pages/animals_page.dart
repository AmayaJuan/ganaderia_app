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
  final String? idAnimal;
  final String raza;
  final String sexo;
  final String? fechaNacimiento;
  final String? idLote;
  final String? nombreLote;
  final double? ultimoPeso;
  final String? ultimaFechaPeso;

  _Animal({
    required this.id,
    this.idAnimal,
    required this.raza,
    required this.sexo,
    this.fechaNacimiento,
    this.idLote,
    this.nombreLote,
    this.ultimoPeso,
    this.ultimaFechaPeso,
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
            id, id_animal, raza, sexo, fecha_nacimiento, id_lote,
            lotes(nombre),
            registro_peso(peso, fecha)
          ''')
          .order('created_at', ascending: false);

      _animales = (data as List).map((item) {
        // Obtener último peso
        double? ultimoPeso;
        String? ultimaFechaPeso;
        final pesos = item['registro_peso'] as List?;
        if (pesos != null && pesos.isNotEmpty) {
          pesos.sort(
            (a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String),
          );
          ultimoPeso = (pesos.first['peso'] as num).toDouble();
          ultimaFechaPeso = pesos.first['fecha'] as String?;
        }

        return _Animal(
          id: item['id'],
          raza: item['raza'] ?? '—',
          sexo: item['sexo'] ?? '—',
          fechaNacimiento: item['fecha_nacimiento'],
          idAnimal: item['id_animal'] as String?,
          idLote: item['id_lote'],
          nombreLote: item['lotes']?['nombre'],
          ultimoPeso: ultimoPeso,
          ultimaFechaPeso: ultimaFechaPeso,
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
        // ── Encabezado (responsive) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.green),
                    onPressed: _cargarDatos,
                    tooltip: 'Actualizar',
                  ),
                  const Spacer(),
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
                                    'ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                                    DataCell(
                                      Text(
                                        a.idAnimal ?? '—',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.green,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(a.raza)),
                                    DataCell(_sexoBadge(a.sexo)),
                                    DataCell(Text(a.edad)),
                                    DataCell(Text(a.nombreLote ?? '—')),
                                    DataCell(
                                      a.ultimoPeso != null
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${a.ultimoPeso!.toStringAsFixed(1)} kg',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.green,
                                                  ),
                                                ),
                                                if (a.ultimaFechaPeso != null)
                                                  Text(
                                                    _fmtFecha(
                                                      a.ultimaFechaPeso!,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : const Text('—'),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.show_chart,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                            tooltip: 'Historial de pesos',
                                            onPressed: () =>
                                                _mostrarHistorialPesos(a),
                                          ),
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

  // ── Utilidad: formatea 'yyyy-MM-dd' → 'dd/MM/yyyy' ─────────────────────────
  static String _fmtFecha(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  // ── Historial de pesos ────────────────────────────────────────────────────
  void _mostrarHistorialPesos(_Animal animal) {
    showDialog(
      context: context,
      builder: (ctx) => _HistorialPesosDialog(
        db: _db,
        animal: animal,
        onPesoEliminado: _cargarDatos,
      ),
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
            child: const Icon(
              Icons.agriculture,
              size: 48,
              color: AppColors.green,
            ),
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
  // Sentinel para "Sin lote" — evita el bug de Flutter con value: null en DropdownButtonFormField
  static const _kSinLote = '__none__';

  void _mostrarFormulario({_Animal? animal}) {
    final idAnimalCtrl = TextEditingController(text: animal?.idAnimal ?? '');
    final kRazas = const [
      'Brahman',
      'Cebú',
      'Angus',
      'Hereford',
      'Simmental',
      'Charolais',
      'Limousin',
      'Brangus',
      'Gyr',
      'Romosinuano',
      'Blanco Orejinegro',
      'Normando',
      'Holstein',
      'Pardo Suizo',
      'Otro',
    ];
    String razaVal = kRazas.contains(animal?.raza) ? animal!.raza : 'Otro';
    // En edición, el campo peso siempre empieza vacío:
    // solo se inserta en registro_peso si el usuario escribe un valor nuevo.
    final pesoCtrl = TextEditingController();
    String sexo = animal?.sexo ?? 'Macho';
    // Usamos sentinel para evitar bug de Flutter con null en DropdownButtonFormField
    String loteVal = animal?.idLote ?? _kSinLote;
    DateTime? fechaNac = animal?.fechaNacimiento != null
        ? DateTime.tryParse(animal!.fechaNacimiento!)
        : null;
    DateTime fechaPeso = DateTime.now();
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
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── ID Animal ──────────────────────────────
                    TextFormField(
                      controller: idAnimalCtrl,
                      decoration: InputDecoration(
                        labelText: 'ID Animal (arete / chip)',
                        hintText: 'Ej: 00123, CH-456',
                        prefixIcon: const Icon(Icons.tag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Raza ───────────────────────────────────
                    DropdownButtonFormField<String>(
                      initialValue: razaVal,
                      decoration: InputDecoration(
                        labelText: 'Raza *',
                        prefixIcon: const Icon(Icons.agriculture),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: kRazas
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => razaVal = v ?? 'Otro'),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'La raza es obligatoria'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // ── Sexo ───────────────────────────────────
                    DropdownButtonFormField<String>(
                      initialValue: sexo,
                      decoration: InputDecoration(
                        labelText: 'Sexo *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                        DropdownMenuItem(
                          value: 'Hembra',
                          child: Text('Hembra'),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => sexo = v!),
                    ),
                    const SizedBox(height: 14),

                    // ── Lote (sentinel fix) ────────────────────
                    DropdownButtonFormField<String>(
                      initialValue: loteVal,
                      decoration: InputDecoration(
                        labelText: 'Lote',
                        prefixIcon: const Icon(Icons.folder_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: _kSinLote,
                          child: Text('Sin lote'),
                        ),
                        ..._lotes.map(
                          (l) => DropdownMenuItem(
                            value: l['id'] as String,
                            child: Text(l['nombre'] as String),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setModalState(() => loteVal = v ?? _kSinLote),
                    ),
                    const SizedBox(height: 14),

                    // ── Fecha nacimiento ───────────────────────
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
                              Icons.cake_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fechaNac != null
                                  ? '${fechaNac!.day.toString().padLeft(2, '0')}/${fechaNac!.month.toString().padLeft(2, '0')}/${fechaNac!.year}'
                                  : 'Fecha de nacimiento (opcional)',
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
                    const SizedBox(height: 14),

                    // ── Peso ───────────────────────────────────
                    TextFormField(
                      controller: pesoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: esEdicion
                            ? 'Registrar nuevo peso (opcional)'
                            : 'Peso inicial (kg)',
                        hintText: esEdicion
                            ? 'Dejar vacío para no registrar'
                            : 'Ej: 250.5',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                        suffixText: 'kg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final p = double.tryParse(
                            v.trim().replaceAll(',', '.'),
                          );
                          if (p == null || p <= 0) {
                            return 'Ingresa un peso válido mayor a 0';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Fecha del peso ─────────────────────────
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: fechaPeso,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => fechaPeso = picked);
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
                              Icons.event_note_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${fechaPeso.day.toString().padLeft(2, '0')}/${fechaPeso.month.toString().padLeft(2, '0')}/${fechaPeso.year}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const Spacer(),
                            const Text(
                              'Fecha del peso',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
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
                  idAnimal: idAnimalCtrl.text.trim().isEmpty
                      ? null
                      : idAnimalCtrl.text.trim(),
                  raza: razaVal,
                  sexo: sexo,
                  idLote: loteVal == _kSinLote ? null : loteVal,
                  fechaNac: fechaNac,
                  pesoKg: pesoCtrl.text.trim().isEmpty
                      ? null
                      : double.tryParse(
                          pesoCtrl.text.trim().replaceAll(',', '.'),
                        ),
                  fechaPeso: fechaPeso,
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
    String? idAnimal,
    required String raza,
    required String sexo,
    String? idLote,
    DateTime? fechaNac,
    double? pesoKg,
    required DateTime fechaPeso,
    required bool esEdicion,
  }) async {
    try {
      final data = <String, dynamic>{
        if (idAnimal != null && idAnimal.isNotEmpty) 'id_animal': idAnimal,
        'raza': raza,
        'sexo': sexo,
        'id_lote': idLote, // null limpia el lote correctamente
        if (fechaNac != null)
          'fecha_nacimiento':
              '${fechaNac.year}-${fechaNac.month.toString().padLeft(2, '0')}-${fechaNac.day.toString().padLeft(2, '0')}',
      };

      String animalId;
      if (esEdicion && id != null) {
        await _db.from('animales').update(data).eq('id', id);
        animalId = id;
      } else {
        final inserted = await _db
            .from('animales')
            .insert(data)
            .select('id')
            .single();
        animalId = inserted['id'] as String;
      }

      // Registrar peso en registro_peso con la fecha elegida
      if (pesoKg != null) {
        final fechaStr =
            '${fechaPeso.year}-${fechaPeso.month.toString().padLeft(2, '0')}-${fechaPeso.day.toString().padLeft(2, '0')}';
        await _db.from('registro_peso').insert({
          'id_animal': animalId,
          'peso': pesoKg,
          'fecha': fechaStr,
        });
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

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo: Historial de pesos por animal
// ─────────────────────────────────────────────────────────────────────────────
class _HistorialPesosDialog extends StatefulWidget {
  final dynamic db;
  final _Animal animal;
  final VoidCallback onPesoEliminado;

  const _HistorialPesosDialog({
    required this.db,
    required this.animal,
    required this.onPesoEliminado,
  });

  @override
  State<_HistorialPesosDialog> createState() => _HistorialPesosDialogState();
}

class _HistorialPesosDialogState extends State<_HistorialPesosDialog> {
  List<Map<String, dynamic>> _registros = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await widget.db
          .from('registro_peso')
          .select('id, peso, fecha')
          .eq('id_animal', widget.animal.id)
          .order('fecha', ascending: false);
      setState(() {
        _registros = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  String _fmt(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  Future<void> _eliminarRegistro(String registroId) async {
    try {
      await widget.db.from('registro_peso').delete().eq('id', registroId);
      widget.onPesoEliminado();
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular ganancia entre pesajes (orden descendente → diff con siguiente)
    final List<double?> ganancias = List.filled(_registros.length, null);
    for (int i = 0; i < _registros.length - 1; i++) {
      final actual = (_registros[i]['peso'] as num).toDouble();
      final anterior = (_registros[i + 1]['peso'] as num).toDouble();
      ganancias[i] = actual - anterior;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          const Icon(Icons.show_chart, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de pesos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.animal.raza} · ID: ${widget.animal.idAnimal ?? widget.animal.id.substring(0, 8)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 380,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _registros.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monitor_weight_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sin registros de peso',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // ── Resumen ──────────────────────────────────────
                  if (_registros.length >= 2)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statChip(
                            'Primer peso',
                            '${(_registros.last['peso'] as num).toStringAsFixed(1)} kg',
                            Icons.start,
                            Colors.grey,
                          ),
                          _statChip(
                            'Último peso',
                            '${(_registros.first['peso'] as num).toStringAsFixed(1)} kg',
                            Icons.flag_outlined,
                            AppColors.green,
                          ),
                          _statChip(
                            'Ganancia total',
                            () {
                              final g =
                                  (_registros.first['peso'] as num) -
                                  (_registros.last['peso'] as num);
                              return '${g >= 0 ? '+' : ''}${g.toStringAsFixed(1)} kg';
                            }(),
                            Icons.trending_up,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                  // ── Lista de registros ───────────────────────────
                  Expanded(
                    child: ListView.separated(
                      itemCount: _registros.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final r = _registros[i];
                        final peso = (r['peso'] as num).toDouble();
                        final fecha = r['fecha'] as String;
                        final ganancia = ganancias[i];
                        final esMasReciente = i == 0;

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: esMasReciente
                                ? AppColors.green
                                : Colors.grey.shade200,
                            child: Text(
                              '${_registros.length - i}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: esMasReciente
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                '${peso.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: esMasReciente
                                      ? AppColors.green
                                      : Colors.black87,
                                ),
                              ),
                              if (ganancia != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ganancia >= 0
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${ganancia >= 0 ? '+' : ''}${ganancia.toStringAsFixed(1)} kg',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: ganancia >= 0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            _fmt(fecha),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            tooltip: 'Eliminar registro',
                            onPressed: () async {
                              final confirmar = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: const Text('Eliminar registro'),
                                  content: Text(
                                    '¿Eliminar el peso del ${_fmt(fecha)}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmar == true) {
                                await _eliminarRegistro(r['id'] as String);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
