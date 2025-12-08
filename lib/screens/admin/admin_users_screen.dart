import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Error or Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              // 3. Extract Data safely (Check multiple common field names)
              final photoUrl = data['photoURL'] ?? data['image'];
              // Name: Check 'name', then 'displayName', then 'Unknown'
              final String name = data['name'] ?? data['displayName'] ?? 'Unknown Name';
              // Email: Check 'email'
              final String email = data['email'] ?? 'No Email';
              // Number: Check 'phoneNumber', 'phone', or 'mobile'
              final String phone = data['phoneNumber'] ?? data['phone'] ?? data['mobile'] ?? 'No Number';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                // Profile Picture
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold))
                      : null,
                ),
                // User Name
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                // User Info (Email & Phone)
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // Email Row
                    Row(
                      children: [
                        const Icon(Icons.email, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(child: Text(email, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Phone Row
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(phone, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                // Delete Action
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'delete') {
                      // Optional: Add a confirm dialog here before deleting
                      await d.reference.delete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete User', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
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
