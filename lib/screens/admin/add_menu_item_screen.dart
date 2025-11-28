import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:topd_apps/models/menu_item.dart';
import 'package:topd_apps/services/firestore_service.dart';

class AddMenuItemScreen extends StatefulWidget {
  const AddMenuItemScreen({super.key});

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();

  File? _imageFile; // mobile
  Uint8List? _webImage; // web


  bool _loading = false;

  // 📌 Pick Image (supports Web + Mobile)
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        // WEB: Read as bytes
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      } else {
        // MOBILE: Read as File
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    }
  }


  // 📌 Upload image to Firebase Storage
  Future<String> uploadImage() async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance
        .ref()
        .child("menuImages/$fileName.jpg");

    if (kIsWeb) {
      await ref.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      await ref.putFile(_imageFile!);
    }

    return await ref.getDownloadURL();
  }


  // 📌 Save Product
  Future<void> saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    setState(() => _loading = true);

    try {
      print("Uploading image...");
      final imageUrl = await uploadImage();
      print("Image uploaded: $imageUrl");

      final firestoreService =
      Provider.of<FirestoreService>(context, listen: false);

      final item = MenuItem(
        id: "",
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        category: _categoryController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: imageUrl,
      );

      await firestoreService.addMenuItem(item);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menu item added successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      print("🔥 SAVE ERROR: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Menu Item")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📌 Image Picker UI
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _webImage == null && _imageFile == null
                    ? const Center(child: Text("Tap to select image"))
                    : kIsWeb
                    ? Image.memory(_webImage!, fit: BoxFit.cover)
                    : Image.file(_imageFile!, fit: BoxFit.cover),

              ),
            ),

            const SizedBox(height: 20),

            // 📌 Form Fields
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                    validator: (v) =>
                    v!.isEmpty ? "Enter product name" : null,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: "Description"),
                    maxLines: 2,
                    validator: (v) =>
                    v!.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: "Category"),
                    validator: (v) =>
                    v!.isEmpty ? "Enter category" : null,
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: "Price"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Enter price";
                      if (double.tryParse(v) == null) {
                        return "Invalid number";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 📌 Save Button
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveMenuItem,
                child: const Text("Save Product"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
