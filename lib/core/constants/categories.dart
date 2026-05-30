class CategoryConstants {
  static const List<String> mainCategories = [
    'vehiculos',
    'inmobiliaria',
    'tecnologia',
    'ropa-y-accesorios',
    'servicios',
    'electrodomesticos',
    'empleos',
    'hogar'
  ];

  static const Map<String, String> categoryNames = {
    'vehiculos': 'Vehículos',
    'inmobiliaria': 'Inmobiliaria',
    'tecnologia': 'Tecnología',
    'ropa-y-accesorios': 'Ropa y Accesorios',
    'servicios': 'Servicios',
    'electrodomesticos': 'Electrodomésticos',
    'empleos': 'Empleos',
    'hogar': 'Hogar',
  };

  static const Map<String, List<Map<String, String>>> defaultSubcategories = {
    'vehiculos': [
      {'name': 'Motos Eléctricas y Triciclos', 'slug': 'vehiculos-motos-electricas-y-triciclos'},
      {'name': 'Motos de Combustión', 'slug': 'vehiculos-motos-de-combustion'},
      {'name': 'Repuestos y Accesorios de Motos', 'slug': 'vehiculos-repuestos-y-accesorios-de-motos'},
      {'name': 'Carros', 'slug': 'vehiculos-carros'},
      {'name': 'Repuestos y Accesorios de Carros', 'slug': 'vehiculos-repuestos-y-accesorios-de-carros'},
      {'name': 'Bicicletas', 'slug': 'vehiculos-bicicletas'},
      {'name': 'Alquiler de Carros', 'slug': 'vehiculos-alquiler-de-carros'},
      {'name': 'Otros - Vehículos', 'slug': 'vehiculos-otros-vehiculos'},
    ],
    'inmobiliaria': [
      {'name': 'Casas', 'slug': 'inmobiliaria-casas'},
      {'name': 'Alquiler a Cubanos', 'slug': 'inmobiliaria-alquiler-a-cubanos'},
      {'name': 'Alquiler a Extranjeros', 'slug': 'inmobiliaria-alquiler-a-extranjeros'},
      {'name': 'Alquiler Vacacional', 'slug': 'inmobiliaria-alquiler-vacacional'},
      {'name': 'Permutas', 'slug': 'inmobiliaria-permutas'},
      {'name': 'Otros - Inmobiliaria', 'slug': 'inmobiliaria-otros-inmobiliaria'},
    ],
    'tecnologia': [
      {'name': 'Celulares y Accesorios', 'slug': 'tecnologia-celulares-y-accesorios'},
      {'name': 'Televisores e Imagen', 'slug': 'tecnologia-televisores-e-imagen'},
      {'name': 'Computadoras y Tablets', 'slug': 'tecnologia-computadoras-y-tablets'},
      {'name': 'Accesorios de Computadoras', 'slug': 'tecnologia-accesorios-de-computadoras'},
      {'name': 'Consolas y Videojuegos', 'slug': 'tecnologia-consolas-y-videojuegos'},
      {'name': 'Audífonos, Bocinas y Sonido', 'slug': 'tecnologia-audifonos-bocinas-y-sonido'},
      {'name': 'Cámaras y Fotografía', 'slug': 'tecnologia-camaras-y-fotografia'},
      {'name': 'Otros - Tecnología', 'slug': 'tecnologia-otros-tecnologia'},
    ],
    'ropa-y-accesorios': [
      {'name': 'Ropa de Mujer', 'slug': 'ropa-y-accesorios-ropa-de-mujer'},
      {'name': 'Zapatos de Mujer', 'slug': 'ropa-y-accesorios-zapatos-de-mujer'},
      {'name': 'Ropa de Hombre', 'slug': 'ropa-y-accesorios-ropa-de-hombre'},
      {'name': 'Zapatos de Hombre', 'slug': 'ropa-y-accesorios-zapatos-de-hombre'},
      {'name': 'Relojes, Joyas y Accesorios', 'slug': 'ropa-y-accesorios-relojes-joyas-y-accesorios'},
      {'name': 'Belleza, Maquillaje y Perfumes', 'slug': 'ropa-y-accesorios-belleza-maquillaje-y-perfumes'},
      {'name': 'Otros - Ropa y Accesorios', 'slug': 'ropa-y-accesorios-otros-ropa-y-accesorios'},
    ],
    'servicios': [
      {'name': 'Construcción y Mantenimiento', 'slug': 'servicios-construccion-y-mantenimiento'},
      {'name': 'Catering y Comida a Domicilio', 'slug': 'servicios-catering-y-comida-a-domicilio'},
      {'name': 'Belleza, Salud y Cuidado Personal', 'slug': 'servicios-belleza-salud-y-cuidado-personal'},
      {'name': 'Talleres y Reparaciones', 'slug': 'servicios-talleres-y-reparaciones'},
      {'name': 'Eventos y Entretenimiento', 'slug': 'servicios-eventos-y-entretenimiento'},
      {'name': 'Limpieza y Cuidado', 'slug': 'servicios-limpieza-y-cuidado'},
      {'name': 'Clases y Cursos', 'slug': 'servicios-clases-y-cursos'},
      {'name': 'Informática, Creatividad y Marketing', 'slug': 'servicios-informatica-creatividad-y-marketing'},
      {'name': 'Transporte y Logística', 'slug': 'servicios-transporte-y-logistica'},
    ],
    'electrodomesticos': [
      {'name': 'Refrigeradores y Neveras', 'slug': 'electrodomesticos-refrigeradores-y-neveras'},
      {'name': 'Lavadoras y Secadoras', 'slug': 'electrodomesticos-lavadoras-y-secadoras'},
      {'name': 'Cocinas y Hornos', 'slug': 'electrodomesticos-cocinas-y-hornos'},
      {'name': 'Ventiladores', 'slug': 'electrodomesticos-ventiladores'},
      {'name': 'Aire Acondicionado', 'slug': 'electrodomesticos-aire-acondicionado'},
      {'name': 'Pequeño Electrodoméstico', 'slug': 'electrodomesticos-pequeno-electrodomestico'},
      {'name': 'Otros - Electrodomésticos', 'slug': 'electrodomesticos-otros-electrodomesticos'},
    ],
    'empleos': [
      {'name': 'Ofertas de Empleo', 'slug': 'empleos-ofertas-de-empleo'},
      {'name': 'Busco Empleo', 'slug': 'empleos-busco-empleo'},
    ],
    'hogar': [
      {'name': 'Muebles', 'slug': 'hogar-muebles'},
      {'name': 'Arte, Antigüedades y Colección', 'slug': 'hogar-arte-antiguedades-y-coleccion'},
      {'name': 'Plantas y Estaciones de Energía', 'slug': 'hogar-plantas-y-estaciones-de-energia'},
      {'name': 'Materiales de Construcción', 'slug': 'hogar-materiales-de-construccion'},
      {'name': 'Ferretería y Herramientas', 'slug': 'hogar-ferreteria-y-herramientas'},
      {'name': 'Artículos del Hogar', 'slug': 'hogar-articulos-del-hogar'},
      {'name': 'Otros - Hogar', 'slug': 'hogar-otros-hogar'},
    ]
  };
}
