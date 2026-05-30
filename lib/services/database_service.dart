import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream de estadísticas globales
  Stream<DocumentSnapshot> streamStatsGlobales() {
    return _db.collection('stats').doc('globales').snapshots();
  }

  Future<void> saveStatsGlobales(Map<String, dynamic> data) {
    return _db.collection('stats').doc('globales').set(data, SetOptions(merge: true));
  }

  // Stream de banners
  Stream<DocumentSnapshot> streamBanners() {
    return _db.collection('stats').doc('banners').snapshots();
  }

  // Stream de categorías/subcategorías
  Stream<DocumentSnapshot> streamCategorias() {
    return _db.collection('stats').doc('categorias').snapshots();
  }

  // Gestión de Usuario en Firestore
  Future<DocumentSnapshot> getUsuario(String userId) {
    return _db.collection('usuarios').doc(userId).get();
  }

  Future<void> saveUsuario(String userId, Map<String, dynamic> data) {
    return _db.collection('usuarios').doc(userId).set(data, SetOptions(merge: true));
  }

  // Registro de dispositivos para prueba gratuita
  Future<DocumentSnapshot> getDispositivoPrueba(String deviceId) {
    return _db.collection('dispositivos_pruebas').doc(deviceId).get();
  }

  Future<void> registerDispositivoPrueba(String deviceId, Map<String, dynamic> data) {
    return _db.collection('dispositivos_pruebas').doc(deviceId).set(data);
  }

  // Administrador
  Stream<QuerySnapshot> streamTodosUsuarios() {
    return _db.collection('usuarios').snapshots();
  }
}
