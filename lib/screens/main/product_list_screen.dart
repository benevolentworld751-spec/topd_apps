import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  final String categoryId; // This receives the ID or Name passed from MenuScreen
  final String categoryName;

  const ProductListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ----------------- DEBUG MODE -----------------
        // The filter is commented out so we can see ALL items
        // and check what is actually stored in the 'category' field.
        stream: FirebaseFirestore.instance
            .collection('menuItems')
        // .where('category', isEqualTo: categoryId) // <--- UNCOMMENT THIS LATER
            .snapshots(),
        // ----------------------------------------------
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ----------------- DEBUG LOGS -----------------
          // Check your "Run" console to see these logs!
          if (snapshot.hasData) {
            print("\n================ DEBUG START ================");
            print("App is looking for category: '$categoryId'");
            print("Found ${snapshot.data!.docs.length} total items in database.");

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              // Safely get fields to avoid crashes during debug
              final itemName = data['name'] ?? 'No Name';
              final itemCategory = data['category'] ?? 'NO CATEGORY FIELD';

              print("Item: '$itemName' | DB Category: '$itemCategory'");

              // Helper to spot spaces
              if (itemCategory.toString().trim() != itemCategory.toString()) {
                print("   >>> WARNING: Item '$itemName' has extra spaces in category!");
              }
            }
            print("================ DEBUG END ==================\n");
          }
          // ----------------------------------------------

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text("No items found in database",
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final data = items[index].data() as Map<String, dynamic>;
              return MenuItemCard(
                itemId: items[index].id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}

class MenuItemCard extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;

  const MenuItemCard({super.key, required this.itemId, required this.data});

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard> {
  int _selectedVariantIndex = 0;

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'Unknown';
    final image = widget.data['image'] ?? '';
    final isVeg = widget.data['isVeg'] ?? false;

    // --- FIX FOR VARIANTS DATA STRUCTURE ---
    List<dynamic> variantsList = [];

    // 1. Check if 'variants' is a List (Ideal structure)
    if (widget.data['variants'] is List) {
      variantsList = widget.data['variants'];
    }
    // 2. Check if 'variants' is a Map (Your current structure)
    else if (widget.data['variants'] is Map) {
      variantsList.add(widget.data['variants']);
    }
    // 3. Fallback: Check for old 'price' field
    else if (widget.data['price'] != null) {
      variantsList.add({
        'price': widget.data['price'],
        'unit': 'Full'
      });
    }

    // If still empty, don't crash, just show 'Unavailable'
    if (variantsList.isEmpty) {
      return const SizedBox();
    }

    final currentVariant = variantsList[_selectedVariantIndex];
    final currentPrice = currentVariant['price'];
    final currentUnit = currentVariant['unit'] ?? 'Full';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: image.isNotEmpty
                  ? Image.network(
                image, width: 90, height: 90, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 90, height: 90, color: Colors.grey[200], child: const Icon(Icons.fastfood)),
              )
                  : Container(width: 90, height: 90, color: Colors.grey[200], child: const Icon(Icons.fastfood)),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: isVeg ? Colors.green : Colors.red, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dropdown (Only if multiple variants exist)
                  if (variantsList.length > 1)
                    DropdownButton<int>(
                      value: _selectedVariantIndex,
                      isDense: true,
                      items: List.generate(variantsList.length, (index) {
                        final v = variantsList[index];
                        return DropdownMenuItem(value: index, child: Text("${v['unit']}"));
                      }),
                      onChanged: (val) => setState(() => _selectedVariantIndex = val!),
                    )
                  else
                    Text("$currentUnit", style: TextStyle(color: Colors.grey[600], fontSize: 13)),

                  const SizedBox(height: 8),

                  // Price and Add
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("₹$currentPrice", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added $name")));
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            minimumSize: const Size(0, 32)
                        ),
                        child: const Text("ADD"),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}