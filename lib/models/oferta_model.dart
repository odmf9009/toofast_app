class Oferta {
  final String id;
  final String titulo;
  final String precio;
  final String tiempo;
  final String ubicacion;
  final String fotos;
  final String visitas;
  final String enlace;
  final String imagen;
  final String detalles;

  Oferta({
    required this.id,
    required this.titulo,
    required this.precio,
    required this.tiempo,
    required this.ubicacion,
    required this.fotos,
    required this.visitas,
    required this.enlace,
    required this.imagen,
    required this.detalles,
  });

  factory Oferta.fromMap(Map<String, String> map) {
    return Oferta(
      id: map['id'] ?? '',
      titulo: map['titulo'] ?? '',
      precio: map['precio'] ?? '',
      tiempo: map['tiempo'] ?? '',
      ubicacion: map['ubicacion'] ?? '',
      fotos: map['fotos'] ?? '',
      visitas: map['visitas'] ?? '',
      enlace: map['enlace'] ?? '',
      imagen: map['imagen'] ?? '',
      detalles: map['detalles'] ?? '',
    );
  }

  Map<String, String> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'precio': precio,
      'tiempo': tiempo,
      'ubicacion': ubicacion,
      'fotos': fotos,
      'visitas': visitas,
      'enlace': enlace,
      'imagen': imagen,
      'detalles': detalles,
    };
  }
}
