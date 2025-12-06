// TODO Implement this library.
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController nameController = TextEditingController();
  File? imageFile;
  bool loading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => imageFile = File(picked.path));
  }

  Future<String> uploadImage(File file) async {
    final ref = FirebaseStorage.instance
        .ref("category_images/${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> saveCategory() async {
    if (nameController.text.isEmpty || imageFile == null) return;

    setState(() => loading = true);

    try {
      final imageUrl = await uploadImage(imageFile!);

      await FirebaseFirestore.instance.collection("categories").add({
        "name": nameController.text.trim(),
        "imageUrl": imageUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Category")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Category Name"),
            ),

            const SizedBox(height: 20),

            InkWell(
              onTap: pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                color: Colors.grey[300],
                child: imageFile == null
                    ? const Icon(Icons.add_photo_alternate, size: 50)
                    : Image.file(imageFile!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : saveCategory,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Save Category"),
            ),
          ],
        ),
      ),
    );
  }
}
