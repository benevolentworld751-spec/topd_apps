import 'dart:typed_data'; // For handling web images
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For image upload
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Required for picking images

class EditMenuItemScreen extends StatefulWidget {
  final String itemId;
  const EditMenuItemScreen({super.key, required this.itemId});

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Controllers for adding a NEW variant (e.g. Price: 200, Unit: 4 PC)
  final _addPriceController = TextEditingController();
  final _addUnitController = TextEditingController();

  String? _selectedCategory;
  // Default to false. In your menu: Green Dot = Veg, Red Dot = Non-Veg
  bool _isVeg = false;
  // Stores the list of price/unit pairs
  List<Map<String, dynamic>> _variants = [];
  // Image handling
  Uint8List? _webImage; // For new picked image
  String? _currentImageUrl; // For existing image from DB
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addPriceController.dispose();
    _addUnitController.dispose();
    super.dispose();
  }
  Future<void> _loadItem() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('menuItems').doc(widget.itemId).get();
      if (doc.exists) {
        final data = doc.data()!;

        _nameController.text = data['name'] ?? '';
        _selectedCategory = data['category'];
        _currentImageUrl = data['image'];
        _isVeg = data['isVeg'] ?? false;

        // Load variants. If old data format (single price), convert it to variant list
        if (data['variants'] != null) {
          _variants = List<Map<String, dynamic>>.from(data['variants']);
        } else if (data['price'] != null) {
          _variants.add({
            'price': data['price'],
            'unit': 'Full' // Default unit for migrated data
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => _loading = false);
    }
  }
  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result != null) {
      final bytes = await result.readAsBytes();
      setState(() => _webImage = bytes);
    }
  }
  // Add a price variant to the list
  void _addVariant() {
    final price = double.tryParse(_addPriceController.text.trim());
    final unit = _addUnitController.text.trim().toUpperCase();

    if (price == null || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both Price and Unit (e.g., 4 PC)')),
      );
      return;
    }
    setState(() {
      _variants.add({'price': price, 'unit': unit});
      _addPriceController.clear();
      _addUnitController.clear();
    });
  }
  // Remove a variant
  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please check inputs')));
      return;
    }
    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one price variant')));
      return;
    }
    setState(() => _loading = true);
    try {
      String finalImageUrl = _currentImageUrl ?? '';
      // Upload new image if selected
      if (_webImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('menuItems/${widget.itemId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_webImage!);
        finalImageUrl = await ref.getDownloadURL();
      }
      // Update Firestore
      await FirebaseFirestore.instance.collection('menuItems').doc(widget.itemId).update({
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'image': finalImageUrl,
        'isVeg': _isVeg,
        'variants': _variants, // Saving the list: [{'price':200, 'unit':'4 PC'}, ...]
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic to show New Image (Bytes) vs Existing Image (Network) vs Placeholder
    Widget imageWidget;
    if (_webImage != null) {
      imageWidget = Image.memory(_webImage!, width: 100, height: 100, fit: BoxFit.cover);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageWidget = Image.network(_currentImageUrl!, width: 100, height: 100, fit: BoxFit.cover);
    } else {
      imageWidget = Container(color: Colors.grey[300], width: 100, height: 100, child: const Icon(Icons.add_a_photo));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Menu Item')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Image Section ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageWidget,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text("Tap image to change", style: TextStyle(color: Colors.grey, fontSize: 12))),
              const SizedBox(height: 20),
              // --- 2. Category & Name ---
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('categories').get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: snapshot.data!.docs.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c['name']));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),
              // --- 3. Veg/Non-Veg Switch ---
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4)
                ),
                child: SwitchListTile(
                  title: Text(
                    _isVeg ? "Vegetarian" : "Non-Vegetarian",
                    style: TextStyle(fontWeight: FontWeight.bold, color: _isVeg ? Colors.green : Colors.red),
                  ),
                  value: _isVeg,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  onChanged: (val) => setState(() => _isVeg = val),
                ),
              ),
              const SizedBox(height: 24),
              // --- 4. Variants (Price & Unit) ---
              const Text("Price & Portions", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // List of existing variants
              ..._variants.asMap().entries.map((entry) {
                int idx = entry.key;
                Map val = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text("₹${val['price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Unit: ${val['unit']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeVariant(idx),
                    ),
                  ),
                );
              }),

              // Add new variant input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _addUnitController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Unit (e.g. 4 PC)', isDense: true, border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                    onPressed: _addVariant,
                  )
                ],
              ),
              const SizedBox(height: 32),

              // --- 5. Save Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  onPressed: _loading ? null : _saveItem,
                  child: const Text('UPDATE ITEM'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}