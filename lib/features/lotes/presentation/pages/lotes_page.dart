import 'package:flutter/material.dart';

class LotesPage extends StatefulWidget {
  const LotesPage({super.key});

  @override
  State<LotesPage> createState() => _LotesPageState();
}

// ── MODELO ───────────────────────────────────────────
class Lote {
  final String id;
  String nombre;
  String descripcion;
  List<String> animales;

  Lote({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.animales = const [],
  });
}

class _LotesPageState extends State<LotesPage> {
  static const _green = Color(0xFF20A67A);

  final List<Lote> _lotes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gestión de Lotes',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF20A67A))),
                    Text('Administre las áreas de pastoreo',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Lote'),
                  onPressed: () => _mostrarFormulario(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Lista de lotes ──
            Expanded(
              child: _lotes.isEmpty
                  ? _EmptyState(onAgregar: () => _mostrarFormulario())
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _lotes.length,
                      itemBuilder: (ctx, i) => _LoteCard(
                        lote: _lotes[i],
                        onEditar: () => _mostrarFormulario(lote: _lotes[i]),
                        onEliminar: () => _confirmarEliminar(_lotes[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formulario crear/editar ──────────────────────
  void _mostrarFormulario({Lote? lote}) {
    final nombreCtrl =
        TextEditingController(text: lote?.nombre ?? '');
    final descCtrl =
        TextEditingController(text: lote?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();
    final esEdicion = lote != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(esEdicion ? Icons.edit : Icons.add_circle,
                color: const Color(0xFF20A67A)),
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
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF20A67A), width: 2),
                    ),
                  ),
                  validator: (v) => v!.trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Ej: Área de pastoreo rotativo',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF20A67A), width: 2),
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
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20A67A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                if (esEdicion) {
                  lote.nombre = nombreCtrl.text.trim();
                  lote.descripcion = descCtrl.text.trim();
                } else {
                  _lotes.add(Lote(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    nombre: nombreCtrl.text.trim(),
                    descripcion: descCtrl.text.trim(),
                  ));
                }
              });
              Navigator.pop(ctx);
              _mostrarSnack(
                  esEdicion ? 'Lote actualizado' : 'Lote creado');
            },
            child: Text(esEdicion ? 'Guardar cambios' : 'Crear lote'),
          ),
        ],
      ),
    );
  }

  // ── Confirmar eliminar ───────────────────────────
  void _confirmarEliminar(Lote lote) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar lote'),
          ],
        ),
        content: Text(
            '¿Estás seguro de eliminar "${lote.nombre}"?\n'
            'Esta acción no se puede deshacer.'),
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
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _lotes.remove(lote));
              Navigator.pop(ctx);
              _mostrarSnack('Lote eliminado');
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF20A67A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── CARD DE LOTE ─────────────────────────────────────
class _LoteCard extends StatelessWidget {
  final Lote lote;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _LoteCard({
    required this.lote,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono + botones editar/eliminar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.grass,
                    color: Color(0xFF20A67A), size: 20),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit,
                    color: Color(0xFF185FA5), size: 18),
                onPressed: onEditar,
                tooltip: 'Editar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete,
                    color: Colors.red, size: 18),
                onPressed: onEliminar,
                tooltip: 'Eliminar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Nombre
          Text(lote.nombre,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          if (lote.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(lote.descripcion,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const Spacer(),
          // Contador animales
          Row(
            children: [
              const Icon(Icons.pets,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${lote.animales.length} animales',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Text('Ver animales',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF20A67A),
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF20A67A), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ESTADO VACÍO ─────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAgregar;
  const _EmptyState({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grass,
                size: 48, color: Color(0xFF20A67A)),
          ),
          const SizedBox(height: 16),
          const Text('No hay lotes registrados',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Crea tu primer lote para organizar el ganado',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20A67A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Crear primer lote'),
            onPressed: onAgregar,
          ),
        ],
      ),
    );
  }
}