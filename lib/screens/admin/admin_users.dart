import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminUsers extends StatelessWidget {
  const AdminUsers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Text("No Users Found"),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              final name = user['name'] ?? "Unknown User";
              final email = user['email'] ?? "No Email";
              final profileImage = user['profileImage'] ?? "";

              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage:
                  profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                  child: profileImage.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(name),
                subtitle: Text(email),
                trailing: PopupMenuButton(
                  onSelected: (value) {
                    if (value == "ban") {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.id)
                          .update({"isBanned": true});
                    }
                    // TODO: View Orders action
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: "ban", child: Text("Ban User")),
                    PopupMenuItem(value: "view", child: Text("View Orders")),
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

