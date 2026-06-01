class LoteModel {
  final String id;
  String nombre;
  String descripcion;
  int animales;

  LoteModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.animales = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'animales': animales,
      };

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    return LoteModel(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      animales: json['animales'] is int
          ? json['animales'] as int
          : int.tryParse('${json['animales']}') ?? 0,
    );
  }
}
