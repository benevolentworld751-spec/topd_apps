import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No orders found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              final userId = data['userId'] ?? '-';
              final status = data['status'] ?? 'new';
              final total = data['total'] ?? 0;

              return ListTile(
                title: Text('Order: ${d.id}'),
                subtitle: Text('User: $userId • Status: $status • Total: ₹$total'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'accept') await d.reference.update({'status': 'accepted'});
                    if (v == 'reject') await d.reference.update({'status': 'rejected'});
                    if (v == 'delete') await d.reference.delete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'accept', child: Text('Accept')),
                    PopupMenuItem(value: 'reject', child: Text('Reject')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
