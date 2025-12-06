import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String orderId;
  final int rating;
  final String comment;
  final double amountPaid;
  final String paymentMethod;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.amountPaid,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      orderId: data['orderId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'amountPaid': amountPaid,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
