import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../providers/toofast_provider.dart';
import '../themes/app_colors.dart';

class PanelAdminUsuariosScreen extends StatelessWidget {
  const PanelAdminUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final toofastProvider = Provider.of<ToofastProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Administración', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Registrados', icon: Icon(Icons.people_outline)),
              Tab(text: 'En Línea', icon: Icon(Icons.bolt)),
            ],
          ),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: toofastProvider.streamUsuarios,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error al cargar usuarios'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final allDocs = snapshot.data!.docs;
              final onlineDocs = allDocs.where((d) {
                final data = d.data() as Map;
                if (data['ultima_conexion'] == null) return false;
                final lastSeen = (data['ultima_conexion'] as Timestamp).toDate();
                return DateTime.now().difference(lastSeen).inMinutes < 5;
              }).toList();

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAdminStat('Registrados', '${allDocs.length}'),
                        _buildAdminStat('Premium', '${allDocs.where((d) => (d.data() as Map)['esPremium'] == true).length}'),
                        _buildAdminStat('En Línea', '${onlineDocs.length}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildUserList(context, allDocs, toofastProvider),
                        _buildUserList(context, onlineDocs, toofastProvider),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<QueryDocumentSnapshot> docs, ToofastProvider toofastProvider) {
    if (docs.isEmpty) {
      return const Center(child: Text('No hay usuarios en esta sección', style: TextStyle(color: Colors.grey)));
    }
    
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final bool isPremium = data['esPremium'] ?? false;
        final lastSeen = (data['ultima_conexion'] as Timestamp?)?.toDate();
        final bool isOnline = lastSeen != null && DateTime.now().difference(lastSeen).inMinutes < 5;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: (data['foto'] != null && data['foto'].isNotEmpty)
                        ? (data['foto'].startsWith('data:image')
                            ? MemoryImage(base64Decode(data['foto'].split(',')[1])) as ImageProvider
                            : NetworkImage(data['foto']))
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: (data['foto'] == null || data['foto'].isEmpty)
                        ? Text(data['nombre']?[0].toUpperCase() ?? '?', style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data['nombre'] ?? 'Sin nombre', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        if (data['esAdmin'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.admin_panel_settings, color: AppColors.adminBlue, size: 14),
                        ],
                      ],
                    ),
                    Text(data['email'] ?? 'Sin email', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (isPremium)
                const Icon(Icons.workspace_premium, color: AppColors.premiumGold, size: 18),
              
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                color: AppColors.surface,
                onSelected: (action) async {
                  final userId = docs[index].id;
                  if (action == 'DEACTIVATE') {
                    await toofastProvider.adminDesactivarPremium(userId);
                  } else if (action == 'TOGGLE_ADMIN') {
                    await toofastProvider.adminAsignarAdmin(userId, !(data['esAdmin'] == true));
                  } else {
                    await toofastProvider.adminActivarPremium(userId, action);
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Acción realizada para ${data['nombre']}')),
                    );
                  }
                },
                itemBuilder: (context) {
                  final currentPlan = data['planActual'];
                  final bool userIsAdmin = data['esAdmin'] == true;
                  
                  return [
                    PopupMenuItem(
                      value: '7 Días', 
                      child: Text('🎁 Activar 7 Días', 
                        style: TextStyle(color: (isPremium && currentPlan == '7 Días') ? AppColors.secondary : Colors.white))
                    ),
                    PopupMenuItem(
                      value: '1 Mes + 10 Días', 
                      child: Text('💎 Activar 1 Mes', 
                        style: TextStyle(color: (isPremium && currentPlan == '1 Mes + 10 Días') ? AppColors.secondary : Colors.white))
                    ),
                    PopupMenuItem(
                      value: '6 Meses + 20 Días', 
                      child: Text('👑 Activar 6 Meses', 
                        style: TextStyle(color: (isPremium && currentPlan == '6 Meses + 20 Días') ? AppColors.secondary : Colors.white))
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'DEACTIVATE', 
                      child: Text('🚫 Desactivar Premium', style: TextStyle(color: AppColors.errorRed))
                    ),
                    PopupMenuItem(
                      value: 'TOGGLE_ADMIN', 
                      child: Text(userIsAdmin ? '👤 Quitar Admin' : '🔑 Hacer Admin', 
                        style: TextStyle(color: userIsAdmin ? Colors.orange : AppColors.adminBlue))
                    ),
                  ];
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
