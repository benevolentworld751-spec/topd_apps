import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMenuItemPage extends StatefulWidget {
  const AddMenuItemPage({super.key});

  @override
  State<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends State<AddMenuItemPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  // Image
  Uint8List? webImage;
  XFile? pickedImage;

  bool isUploading = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  // -------------------- PICK IMAGE --------------------
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? img = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (img == null) {
        print("No image selected");
        return;
      }

      if (kIsWeb) {
        final bytes = await img.readAsBytes();
        setState(() {
          webImage = bytes;
          pickedImage = img;
        });
        print("Image picked for Web, size: ${bytes.lengthInBytes}");
      } else {
        setState(() {
          pickedImage = img;
        });
        print("Image picked for Mobile: ${img.path}");
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // -------------------- UPLOAD IMAGE (FIXED) --------------------
  Future<String> uploadImage() async {
    try {
      String fileName = "menu_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // Correct bucket URL
      final ref = FirebaseStorage.instance
          .refFromURL('gs://topd-app.firebasestorage.app/menuImages/$fileName');

      UploadTask uploadTask;

      if (kIsWeb && webImage != null) {
        final metadata = SettableMetadata(
          contentType: "image/jpeg",
          customMetadata: {"fileName": fileName},
        );
        uploadTask = ref.putData(webImage!, metadata);
      } else if (!kIsWeb && pickedImage != null) {
        uploadTask = ref.putFile(File(pickedImage!.path));
      } else {
        throw "No image selected for upload";
      }

      uploadTask.snapshotEvents.listen((event) {
        print('Upload progress: ${event.bytesTransferred}/${event.totalBytes}');
      }, onError: (e) {
        print('Upload error: $e');
      });

      final snapshot = await uploadTask.whenComplete(() => {});
      final imageUrl = await snapshot.ref.getDownloadURL();

      print("Image uploaded successfully: $imageUrl");
      return imageUrl;

    } catch (e) {
      print("Upload failed: $e");
      throw "Upload failed: $e";
    }
  }



  // -------------------- SAVE PRODUCT --------------------
  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      print("Form not valid");
      return;
    }

    if ((kIsWeb && webImage == null) || (!kIsWeb && pickedImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      print("No image selected");
      return;
    }

    setState(() => isUploading = true);

    try {
      print("Start uploading product...");

      // 1️⃣ Upload image
      String imageUrl = await uploadImage();

      // 2️⃣ Save data to Firestore
      await FirebaseFirestore.instance.collection("menuItems").add({
        "name": nameController.text.trim(),
        "description": descriptionController.text.trim(),
        "price": double.tryParse(priceController.text.trim()) ?? 0.0,
        "category": categoryController.text.trim(),
        "imageUrl": imageUrl,
        "createdAt": Timestamp.now(),
      });

      print("Product saved to Firestore successfully");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product added successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Error saving product: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  // -------------------- IMAGE PREVIEW --------------------
  Widget _buildImagePreview() {
    if (kIsWeb && webImage != null) {
      return Image.memory(webImage!, fit: BoxFit.cover, width: double.infinity);
    } else if (!kIsWeb && pickedImage != null) {
      return Image.file(File(pickedImage!.path), fit: BoxFit.cover, width: double.infinity);
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text("No image selected", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product"),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImagePreview(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text("Tap to upload image", style: TextStyle(color: Colors.grey))),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fastfood),
                ),
                validator: (value) => value!.isEmpty ? "Please enter name" : null,
              ),
              const SizedBox(height: 15),

              // Description
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) => value!.isEmpty ? "Please enter description" : null,
              ),
              const SizedBox(height: 15),

              // Price
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Price (₹)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter price";
                  if (double.tryParse(value) == null) return "Enter a valid number";
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Category
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) => value!.isEmpty ? "Please enter category" : null,
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isUploading ? null : saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isUploading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text("Save Product", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

