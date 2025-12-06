import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No users found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              final photoUrl = data['photoURL'] ?? null;
              final displayName = data['displayName'] ?? data['email'] ?? '-';
              final email = data['email'] ?? '-';

              return ListTile(
                leading: photoUrl != null
                    ? Image.network(photoUrl, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.person, size: 50),
                title: Text(displayName),
                subtitle: Text("Email: $email"),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') await d.reference.delete();
                  },
                  itemBuilder: (_) => const [
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
