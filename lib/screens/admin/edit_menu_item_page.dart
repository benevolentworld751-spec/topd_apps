import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditMenuItemPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const EditMenuItemPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<EditMenuItemPage> createState() => _EditMenuItemPageState();
}

class _EditMenuItemPageState extends State<EditMenuItemPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  File? newImageFile;
  bool isUpdating = false;
  late String existingImageUrl;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.productData["name"];
    descriptionController.text = widget.productData["description"];
    priceController.text = widget.productData["price"].toString();
    categoryController.text = widget.productData["category"];
    existingImageUrl = widget.productData["imageUrl"];
  }

  Future pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        newImageFile = File(picked.path);
      });
    }
  }

  Future<String> uploadImage(File image) async {
    String filename = "menu_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = FirebaseStorage.instance.ref("menuImages/$filename");
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUpdating = true);

    try {
      String finalImageUrl = existingImageUrl;

      // If new image selected, upload it
      if (newImageFile != null) {
        finalImageUrl = await uploadImage(newImageFile!);
      }

      await FirebaseFirestore.instance
          .collection("menuItems")
          .doc(widget.productId)
          .update({
        "name": nameController.text.trim(),
        "description": descriptionController.text.trim(),
        "price": double.parse(priceController.text),
        "category": categoryController.text.trim(),
        "imageUrl": finalImageUrl,
        "updatedAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product updated successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrange),
                  ),
                  child: newImageFile == null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(existingImageUrl, fit: BoxFit.cover),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(newImageFile!, fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Enter product name" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price (₹)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Enter price" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Enter category" : null,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : updateProduct,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  child: isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Update Product", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
