import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddEditMenuItemScreen extends StatefulWidget {
  final String? itemId; // null = add, non-null = edit
  const AddEditMenuItemScreen({super.key, this.itemId});

  @override
  State<AddEditMenuItemScreen> createState() => _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState extends State<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Controllers for adding a new variant
  final _variantPriceController = TextEditingController();
  final _variantUnitController = TextEditingController();

  String? _selectedCategory;
  bool _isVeg = false; // Default to Non-Veg (Red) as per menu density

  // Store variants locally: e.g. [{'price': 200, 'unit': '4 PC'}, {'price': 350, 'unit': '8 PC'}]
  List<Map<String, dynamic>> _variants = [];

  Uint8List? _webImage;
  String? _image;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _loadItem();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _variantPriceController.dispose();
    _variantUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('menuItems')
          .doc(widget.itemId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _selectedCategory = data['category'];
        _image = data['image'];
        _isVeg = data['isVeg'] ?? false;

        // Load variants if they exist, otherwise try to load old legacy price format
        if (data['variants'] != null) {
          _variants = List<Map<String, dynamic>>.from(data['variants']);
        } else if (data['price'] != null) {
          // Backward compatibility for your old data
          _variants.add({
            'price': data['price'],
            'unit': 'Full'
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading item: $e");
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (result != null) {
      final bytes = await result.readAsBytes();
      setState(() => _webImage = bytes);
    }
  }

  void _addVariant() {
    final price = double.tryParse(_variantPriceController.text.trim());
    final unit = _variantUnitController.text.trim().toUpperCase();

    if (price == null || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Price and Unit (e.g., 4 PC)')),
      );
      return;
    }

    setState(() {
      _variants.add({
        'price': price,
        'unit': unit,
      });
      _variantPriceController.clear();
      _variantUnitController.clear();
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a category')),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one price variant')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String? uploaded = _image;

      if (_webImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('menuItems/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_webImage!);
        uploaded = await ref.getDownloadURL();
      }

      final data = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'isVeg': _isVeg,
        'image': uploaded ?? '',
        'variants': _variants, // Saving the list of price/units
        'searchKeywords': _generateSearchKeywords(_nameController.text.trim()), // Optional helper
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.itemId == null) {
        await FirebaseFirestore.instance.collection('menuItems').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('menuItems')
            .doc(widget.itemId)
            .update(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _generateSearchKeywords(String name) {
    List<String> keywords = [];
    String temp = "";
    for (int i = 0; i < name.length; i++) {
      temp = temp + name[i].toLowerCase();
      keywords.add(temp);
    }
    return keywords;
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _webImage != null
        ? Image.memory(_webImage!, width: 120, height: 120, fit: BoxFit.cover)
        : (_image != null && _image!.isNotEmpty
        ? Image.network(_image!, width: 120, height: 120, fit: BoxFit.cover)
        : Container(
        width: 120, height: 120,
        color: Colors.grey[200],
        child: const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'Add Menu Item' : 'Edit Menu Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Image Picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageWidget,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fastfood),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),

                // 3. Category Dropdown
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('categories').get(),
                  builder: (context, snapshot) {
                    // While loading or if empty, show a basic dropdown or loader
                    if (!snapshot.hasData) return const LinearProgressIndicator();

                    final cats = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: cats.map((c) {
                        final data = c.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: c.id, // Or data['name'] if you prefer storing name directly
                          child: Text(data['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? 'Select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. Veg / Non-Veg Switch
                SwitchListTile(
                  title: Text(
                    _isVeg ? "Vegetarian" : "Non-Vegetarian",
                    style: TextStyle(
                        color: _isVeg ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  subtitle: const Text("Toggle based on the dot color in menu"),
                  value: _isVeg,
                  activeColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red.withOpacity(0.3),
                  onChanged: (val) => setState(() => _isVeg = val),
                ),

                const Divider(thickness: 1, height: 30),

                // 5. Variants Section (Price & Units)
                const Text(
                  "Price & Portions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text("Add options like: 200 / 4 PC", style: TextStyle(color: Colors.grey)),

                // List of added variants
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _variants.length,
                  itemBuilder: (ctx, index) {
                    final variant = _variants[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.local_offer_outlined),
                        title: Text("₹${variant['price']}"),
                        subtitle: Text("Unit: ${variant['unit']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeVariant(index),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // Input row for new variant
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _variantPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price (₹)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _variantUnitController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Unit (e.g. 4 PC)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addVariant,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12)
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 6. Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading ? null : _saveItem,
                    child: Text(
                      widget.itemId == null ? 'ADD ITEM TO MENU' : 'UPDATE ITEM',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}