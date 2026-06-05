import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Vista de gestión de lotes — persistencia en Supabase.
class LotesPage extends StatefulWidget {
  const LotesPage({super.key});

  @override
  State<LotesPage> createState() => _LotesPageState();
}

class _LoteModel {
  final String id;
  String nombre;
  String descripcion;
  int animales;

  _LoteModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.animales = 0,
  });
}

class _LotesPageState extends State<LotesPage> {
  final _db = Supabase.instance.client;
  List<_LoteModel> _lotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarLotes();
  }

  Future<void> _cargarLotes() async {
    setState(() => _isLoading = true);
    try {
      // Traer lotes con conteo de animales asociados
      final data = await _db
          .from('lotes')
          .select('id, nombre, descripcion, animales(count)')
          .order('nombre');

      setState(() {
        _lotes = (data as List).map((item) {
          final countList = item['animales'] as List?;
          final count = countList != null && countList.isNotEmpty
              ? (countList.first['count'] as int? ?? 0)
              : 0;
          return _LoteModel(
            id: item['id'] as String,
            nombre: item['nombre'] as String? ?? '',
            descripcion: item['descripcion'] as String? ?? '',
            animales: count,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar lotes: $e');
      }
    }
  }

  Future<void> _guardarLote({
    String? id,
    required String nombre,
    required String descripcion,
  }) async {
    try {
      if (id != null) {
        await _db
            .from('lotes')
            .update({'nombre': nombre, 'descripcion': descripcion})
            .eq('id', id);
      } else {
        await _db.from('lotes').insert({
          'nombre': nombre,
          'descripcion': descripcion,
        });
      }
      await _cargarLotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id != null ? 'Lote actualizado' : 'Lote creado'),
            backgroundColor: AppColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al guardar lote: $e');
    }
  }

  Future<void> _eliminarLote(String id, String nombre) async {
    try {
      await _db.from('lotes').delete().eq('id', id);
      await _cargarLotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lote eliminado'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al eliminar lote: $e');
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

  void _verAnimalesDelLote(_LoteModel lote) {
    showDialog(
      context: context,
      builder: (ctx) => _AnimalesLoteDialog(
        db: _db,
        loteId: lote.id,
        loteNombre: lote.nombre,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Lotes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                    ),
                  ),
                  Text(
                    'Administre las áreas de pastoreo',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.green),
                    tooltip: 'Actualizar',
                    onPressed: _cargarLotes,
                  ),
                  const SizedBox(width: 8),
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
                    label: const Text('Nuevo Lote'),
                    onPressed: () => _mostrarFormulario(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _lotes.isEmpty
              ? Center(
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
                          Icons.grass,
                          size: 48,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay lotes registrados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea tu primer lote para organizar el ganado',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
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
                        label: const Text('Crear primer lote'),
                        onPressed: () => _mostrarFormulario(),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: _lotes.length,
                    itemBuilder: (ctx, i) {
                      final lote = _lotes[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.grass,
                                    color: AppColors.green,
                                    size: 20,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppColors.blue,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      _mostrarFormulario(lote: lote),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed: () => _confirmarEliminar(lote),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              lote.nombre,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (lote.descripcion.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                lote.descripcion,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.pets,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${lote.animales} animales',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                InkWell(
                                  onTap: () => _verAnimalesDelLote(lote),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    children: const [
                                      Text(
                                        'Ver animales',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_right,
                                        color: AppColors.green,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _mostrarFormulario({_LoteModel? lote}) {
    final nombreCtrl = TextEditingController(text: lote?.nombre ?? '');
    final descCtrl = TextEditingController(text: lote?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();
    final esEdicion = lote != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              esEdicion ? Icons.edit : Icons.add_circle,
              color: AppColors.green,
            ),
            const SizedBox(width: 8),
            Text(esEdicion ? 'Editar Lote' : 'Nuevo Lote'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre del lote *',
                    hintText: 'Ej: Lote Norte',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Área de pastoreo rotativo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
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
              await _guardarLote(
                id: lote?.id,
                nombre: nombreCtrl.text.trim(),
                descripcion: descCtrl.text.trim(),
              );
            },
            child: Text(esEdicion ? 'Guardar cambios' : 'Crear lote'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(_LoteModel lote) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar lote'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar "${lote.nombre}"?\n'
          'Esta acción no se puede deshacer.',
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
              await _eliminarLote(lote.id, lote.nombre);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _AnimalesLoteDialog extends StatefulWidget {
  final dynamic db;
  final String loteId;
  final String loteNombre;

  const _AnimalesLoteDialog({
    required this.db,
    required this.loteId,
    required this.loteNombre,
  });

  @override
  State<_AnimalesLoteDialog> createState() => _AnimalesLoteDialogState();
}

class _AnimalesLoteDialogState extends State<_AnimalesLoteDialog> {
  List<Map<String, dynamic>> _animales = [];
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
          .from('animales')
          .select(
            'id_animal, raza, sexo, fecha_nacimiento, registro_peso(peso, fecha)',
          )
          .eq('id_lote', widget.loteId)
          .order('raza');

      setState(() {
        _animales = List<Map<String, dynamic>>.from(data);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  String _edad(String? fechaNacimiento) {
    if (fechaNacimiento == null) return '—';
    final nac = DateTime.tryParse(fechaNacimiento);
    if (nac == null) return '—';
    final diff = DateTime.now().difference(nac);
    final years = (diff.inDays / 365).floor();
    final months = ((diff.inDays % 365) / 30).floor();
    if (years > 0) return '$years año${years > 1 ? 's' : ''}';
    return '$months mes${months != 1 ? 'es' : ''}';
  }

  String _ultimoPeso(Map<String, dynamic> animal) {
    final pesos = animal['registro_peso'] as List?;
    if (pesos == null || pesos.isEmpty) return '—';
    pesos.sort(
      (a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String),
    );
    return '${(pesos.first['peso'] as num).toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.grass, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.loteNombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Animales en este lote',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
        width: 500,
        height: 360,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _animales.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay animales en este lote',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.greenLight,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'ID',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Raza',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Sexo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Edad',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Peso',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: _animales.map((a) {
                    final isMacho = a['sexo'] == 'Macho';
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            a['id_animal'] ?? '—',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(Text(a['raza'] ?? '—')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isMacho
                                  ? const Color(0xFFE6F1FB)
                                  : const Color(0xFFFCEBF9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a['sexo'] ?? '—',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isMacho
                                    ? const Color(0xFF185FA5)
                                    : const Color(0xFF8B0066),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(_edad(a['fecha_nacimiento']))),
                        DataCell(
                          Text(
                            _ultimoPeso(a),
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
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
}
