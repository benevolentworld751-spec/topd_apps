// TODO Implement this library.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditCategoryPage extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const EditCategoryPage({super.key, required this.id, required this.data});

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  late TextEditingController nameController;
  File? newImage;
  bool loading = false;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data["name"]);
    imageUrl = widget.data["image"];
  }

  Future pickNewImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => newImage = File(picked.path));
  }

  Future<String> uploadNewImage(File file) async {
    final ref = FirebaseStorage.instance.ref(
        "category_images/${widget.id}_${DateTime.now().millisecondsSinceEpoch}.jpg");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> updateCategory() async {
    setState(() => loading = true);

    try {
      String finalImageUrl = imageUrl!;

      if (newImage != null) {
        finalImageUrl = await uploadNewImage(newImage!);
      }

      await FirebaseFirestore.instance
          .collection("categories")
          .doc(widget.id)
          .update({
        "name": nameController.text.trim(),
        "image": finalImageUrl,
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error updating: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Category")),

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
              onTap: pickNewImage,
              child: Container(
                height: 160,
                width: double.infinity,
                color: Colors.grey[300],
                child: newImage != null
                    ? Image.file(newImage!, fit: BoxFit.cover)
                    : Image.network(imageUrl!, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : updateCategory,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Update Category"),
            ),
          ],
        ),
      ),
    );
  }
}
