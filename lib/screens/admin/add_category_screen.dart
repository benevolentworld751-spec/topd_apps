import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddCategoryScreen extends StatefulWidget {
  final String? categoryId; // null for add, non-null for edit
  const AddCategoryScreen({super.key, this.categoryId});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Uint8List? _webImage; // Holds image data for both Web and Mobile
  String? _image;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _loadCategory();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategory() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .get();

      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _image = doc['image'];
        });
      }
    } catch (e) {
      debugPrint("Error loading category: $e");
    }
    setState(() => _loading = false);
  }

  // --- FIXED IMAGE PICKER ---
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70
      );

      if (result != null) {
        // Read bytes asynchronously OUTSIDE of setState
        final bytes = await result.readAsBytes();

        // Update UI synchronously
        setState(() {
          _webImage = bytes;
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? uploadedUrl = _image;

      // Upload Image if a new one is picked
      if (_webImage != null) {
        // Create a unique filename
        final fileName = 'categories/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);

        // Upload
        await ref.putData(_webImage!);

        // Get URL
        uploadedUrl = await ref.getDownloadURL();
      }

      final data = {
        'name': _nameController.text.trim(),
        'image': uploadedUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(), // Good practice
      };

      if (widget.categoryId == null) {
        // Add new
        await FirebaseFirestore.instance.collection('categories').add(data);
      } else {
        // Update existing
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.categoryId)
            .update(data);
      }

      // Check mounted before popping to avoid errors
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving category: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic to decide which image provider to show
    Widget content;
    if (_webImage != null) {
      content = Image.memory(_webImage!, width: 120, height: 120, fit: BoxFit.cover);
    } else if (_image != null && _image!.isNotEmpty) {
      content = Image.network(_image!, width: 120, height: 120, fit: BoxFit.cover);
    } else {
      content = const Icon(Icons.add_a_photo, size: 50, color: Colors.grey);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryId == null ? 'Add Category' : 'Edit Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 20),

              const Text("Category Image", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Center(child: content),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _loading ? null : _saveCategory,
                  child: Text(
                    widget.categoryId == null ? 'SAVE CATEGORY' : 'UPDATE CATEGORY',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}