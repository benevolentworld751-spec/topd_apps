// class CategoryModel {
//   final String id;
//   final String name;
//   final String image;
//
//   CategoryModel({
//     required this.id,
//     required this.name,
//     required this.image,
//   });
//
//   factory CategoryModel.fromMap(String id, Map<String, dynamic> data) {
//     return CategoryModel(
//       id: id,
//       name: data['name'] ?? '',
//       image: data['image'] ?? '',
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'name': name,
//       'image': image,
//     };
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id; // <--- Add this
  final String name;
  final String image;

  CategoryModel({required this.id, required this.name, required this.image});

  factory CategoryModel.fromSnapshot(DocumentSnapshot doc, Map<String, dynamic> data) {
    return CategoryModel(
      id: doc.id, // <--- Capture the Firestore Document ID here
      name: doc['name'] ?? '',
      image: doc['image'] ?? '',
    );
  }
}
