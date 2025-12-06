import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  Uint8List? _webImage; // For web
  String? _imageUrl;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      _loadCategory();
    }
  }

  Future<void> _loadCategory() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('categories')
        .doc(widget.categoryId)
        .get();

    if (doc.exists) {
      _nameController.text = doc['name'] ?? '';
      _imageUrl = doc['image'] ?? null;
    }

    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (result != null) {
      if (kIsWeb) {
        final bytes = await result.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() async => _webImage = await result.readAsBytes());
  }
  }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? uploadedUrl = _imageUrl;

      if (_webImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('categories/${DateTime.now().millisecondsSinceEpoch}.jpg');

        if (kIsWeb) {
          await ref.putData(_webImage!);
        } else {
          await ref.putData(_webImage!);
        }

        uploadedUrl = await ref.getDownloadURL();
      }

      if (widget.categoryId == null) {
        // Add new
        await FirebaseFirestore.instance.collection('categories').add({
          'name': _nameController.text.trim(),
          'image': uploadedUrl ?? '',
        });
      } else {
        // Update existing
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.categoryId)
            .update({
          'name': _nameController.text.trim(),
          'image': uploadedUrl ?? '',
        });
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving category: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _webImage != null
        ? Image.memory(_webImage!, width: 120, height: 120, fit: BoxFit.cover)
        : (_imageUrl != null
        ? Image.network(_imageUrl!, width: 120, height: 120, fit: BoxFit.cover)
        : const Icon(Icons.image, size: 120, color: Colors.grey));

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
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageWidget,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _saveCategory,
                child: Text(widget.categoryId == null ? 'Save Category' : 'Update Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
