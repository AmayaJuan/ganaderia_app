import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';

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
  bool expandido = false; // ← agregar = false
  List<_AnimalResumen> listaAnimales;
  bool cargandoAnimales = false;

  _LoteModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.animales = 0,
  }) : listaAnimales = const [];
}

class _AnimalResumen {
  final String id;
  final String? idAnimal;
  final String raza;
  final String sexo;
  final double? ultimoPeso;

  _AnimalResumen({
    required this.id,
    this.idAnimal,
    required this.raza,
    required this.sexo,
    this.ultimoPeso,
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

  Future<void> _toggleAnimales(_LoteModel lote) async {
    if (lote.expandido) {
      setState(() => lote.expandido = false);
      return;
    }
    // Expandir y cargar animales
    setState(() {
      lote.expandido = true;
      lote.cargandoAnimales = true;
    });
    try {
      final data = await _db
          .from('animales')
          .select('id, id_animal, raza, sexo, registro_peso(peso, fecha)')
          .eq('id_lote', lote.id)
          .order('id_animal');

      final lista = (data as List).map((a) {
        double? ultimoPeso;
        final pesos = a['registro_peso'] as List?;
        if (pesos != null && pesos.isNotEmpty) {
          pesos.sort(
            (x, y) => (y['fecha'] as String).compareTo(x['fecha'] as String),
          );
          ultimoPeso = (pesos.first['peso'] as num).toDouble();
        }
        return _AnimalResumen(
          id: a['id'] as String,
          idAnimal: a['id_animal'] as String?,
          raza: a['raza'] as String? ?? '—',
          sexo: a['sexo'] as String? ?? '—',
          ultimoPeso: ultimoPeso,
        );
      }).toList();

      setState(() {
        lote.listaAnimales = lista;
        lote.cargandoAnimales = false;
      });
    } catch (e) {
      setState(() => lote.cargandoAnimales = false);
      _mostrarError('Error al cargar animales: $e');
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

  Future<void> _eliminarLote(String id) async {
    try {
      await _db.from('lotes').delete().eq('id', id);
      await _cargarLotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lote eliminado'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Encabezado (responsive) ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.green),
                    tooltip: 'Actualizar',
                    onPressed: _cargarLotes,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Botón en línea separada en móvil
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Lista / Vacío ─────────────────────────────────────────────────
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: _lotes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _buildLoteCard(_lotes[i]),
                ),
        ),
      ],
    );
  }

  // ── Tarjeta de lote con panel expandible ──────────────────────────────────
  Widget _buildLoteCard(_LoteModel lote) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabecera del lote ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grass,
                    color: AppColors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lote.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (lote.descripcion.isNotEmpty)
                        Text(
                          lote.descripcion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.blue, size: 18),
                  onPressed: () => _mostrarFormulario(lote: lote),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  onPressed: () => _confirmarEliminar(lote),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Pie: conteo + botón Ver animales ────────────────────────────
          InkWell(
            onTap: () => _toggleAnimales(lote),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.greenLight.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${lote.animales} animal${lote.animales != 1 ? 'es' : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    lote.expandido ? 'Ocultar animales' : 'Ver animales',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: lote.expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.green,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Panel expandible con lista de animales ──────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: lote.expandido
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _buildPanelAnimales(lote),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelAnimales(_LoteModel lote) {
    if (lote.cargandoAnimales) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (lote.listaAnimales.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            const Text(
              'No hay animales en este lote',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Cabecera de la tabla
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'ID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Raza',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Sexo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Último peso',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filas de animales
        ...lote.listaAnimales.map(
          (a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    a.idAnimal ?? '—',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(a.raza, style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: a.sexo == 'Macho'
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      a.sexo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: a.sexo == 'Macho' ? Colors.blue : Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    a.ultimoPeso != null
                        ? '${a.ultimoPeso!.toStringAsFixed(1)} kg'
                        : '—',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: a.ultimoPeso != null
                          ? AppColors.green
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ── Formulario crear/editar lote ──────────────────────────────────────────
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
              await _eliminarLote(lote.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
