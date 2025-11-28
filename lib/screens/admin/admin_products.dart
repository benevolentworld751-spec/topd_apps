import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'edit_menu_item_page.dart';

class AdminProducts extends StatelessWidget {
  const AdminProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Products")),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add-menu-item');
        },
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("menuItems")
            .orderBy("name")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products available"));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data["imageUrl"] ?? "",
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) =>
                      const Icon(Icons.broken_image, size: 40),
                    ),
                  ),

                  title: Text(
                    data["name"] ?? "No Name",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    "Price: ₹${(data['price'] ?? 0).toString()}",
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✏️ Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditMenuItemPage(
                                productId: doc.id,
                                productData: data,
                              ),
                            ),
                          );
                        },
                      ),

                      // 🗑 Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteDialog(
                            context,
                            doc.id,
                            data["imageUrl"],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔥 Delete Confirmation Dialog + Delete Image from Firebase Storage
  void _showDeleteDialog(
      BuildContext context, String docId, String? imageUrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
            onPressed: () async {
              Navigator.pop(context);

              try {
                // 1️⃣ Delete Firestore Document
                await FirebaseFirestore.instance
                    .collection("menuItems")
                    .doc(docId)
                    .delete();

                // 2️⃣ Delete Image From Firebase Storage
                if (imageUrl != null && imageUrl.trim().isNotEmpty) {
                  try {
                    final ref = FirebaseStorage.instance.refFromURL(imageUrl);
                    await ref.delete();
                    print("Image deleted from storage");
                  } catch (e) {
                    print("Image already deleted or not found: $e");
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Product deleted successfully"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print("Delete failed: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error deleting product: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
