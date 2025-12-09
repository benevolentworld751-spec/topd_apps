import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminMenuItemsScreen extends StatelessWidget {
  const AdminMenuItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Items')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('menuItems').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No menu items found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              final name = data['name'] ?? '-';
              final price = data['price'] ?? 0;
              final category = data['category'] ?? '-';
              final imageUrl = data['image'] ?? null;

              return ListTile(
                leading: imageUrl != null
                    ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.fastfood, size: 50),
                title: Text(name),
                subtitle: Text('₹$price • category: $category'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      Navigator.pushNamed(context, '/admin/editMenuItem', arguments: d.id);
                    }
                    if (v == 'delete') await d.reference.delete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/addMenuItem');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
