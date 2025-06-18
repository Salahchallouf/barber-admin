import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isOpen = false;
  final Set<String> _selectedAppointments = {};
  final _settingsDoc = FirebaseFirestore.instance
      .collection('barber_status')
      .doc('status');

  @override
  void initState() {
    super.initState();
    _settingsDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _isOpen = snapshot.data()?['isOpen'] ?? false;
        });
      }
    });
  }

  void _toggleSalonStatus() async {
    await _settingsDoc.set({'isOpen': !_isOpen});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(!_isOpen ? 'Salon fermé' : 'Salon ouvert')),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ Déconnecté avec succès.')));
  }

  void _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(docId)
        .update({'status': newStatus});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📝 Statut mis à jour : $newStatus')),
    );
  }

  void _deleteSelectedAppointments() async {
    if (_selectedAppointments.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF4E342E),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Supprimer ${_selectedAppointments.length} rendez-vous sélectionné(s) ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFFD7A86E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final docId in _selectedAppointments) {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(docId)
            .delete();
      }

      setState(() => _selectedAppointments.clear());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Rendez-vous supprimés.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _deleteAllAppointments(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF4E342E),
        title: const Text(
          'Supprimer tous les rendez-vous ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cette action est irréversible. Voulez-vous vraiment supprimer tous les rendez-vous ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Color(0xFFD7A86E)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Tous les rendez-vous ont été supprimés.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return DateFormat('dd/MM/yyyy – HH:mm').format(dt);
  }

  Widget _statusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Servi':
        color = Colors.green.shade600;
        icon = Icons.verified;
        break;
      case 'Absent':
        color = Colors.red.shade600;
        icon = Icons.cancel;
        break;
      case 'Confirmé':
        color = Colors.blue.shade600;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.orange.shade700;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E2723),
        title: const Text(
          '📅 Rendez-vous du jour',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (_selectedAppointments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Supprimer sélection',
              onPressed: _deleteSelectedAppointments,
              color: Colors.redAccent,
            ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Tout supprimer',
            onPressed: () => _deleteAllAppointments(context),
            color: const Color(0xFFD7A86E),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => _logout(context),
            color: const Color(0xFFD7A86E),
          ),
          IconButton(
            icon: Icon(_isOpen ? Icons.store_outlined : Icons.storefront),
            tooltip: _isOpen ? 'Fermer le salon' : 'Ouvrir le salon',
            onPressed: _toggleSalonStatus,
            color: const Color(0xFFD7A86E),
          ),
        ],
        elevation: 6,
        shadowColor: Colors.brown.shade900,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4E342E), Color(0xFF212121)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where(
                'timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
              )
              .orderBy('timestamp')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD7A86E)),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun rendez-vous prévu pour aujourd\'hui.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'En attente';
                final isSelected = _selectedAppointments.contains(doc.id);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: isSelected
                      ? Colors.brown.shade800
                      : const Color(0xFF3E2723),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    onLongPress: () {
                      setState(() {
                        if (isSelected) {
                          _selectedAppointments.remove(doc.id);
                        } else {
                          _selectedAppointments.add(doc.id);
                        }
                      });
                    },
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedAppointments.add(doc.id);
                          } else {
                            _selectedAppointments.remove(doc.id);
                          }
                        });
                      },
                      activeColor: Colors.redAccent,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    title: Text(
                      '${data['name']} - ${data['service']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFD7A86E),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📞 ${data['phone']}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '🕓 ${_formatDate(data['timestamp'])}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          _statusBadge(status),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFFD7A86E),
                      ),
                      onSelected: (val) => _updateStatus(doc.id, val),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'Confirmé',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('✅ Confirmé'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'Absent',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Text('❌ Absent'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'En attente',
                          child: Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('🕓 En attente'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
