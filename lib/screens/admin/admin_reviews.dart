import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  int? _starFilter; // null = show all
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _deleteReview(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text("Are you sure you want to delete this review?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('reviews').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete review: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guest Reviews"),
      ),
      body: Column(
        children: [
          // ---------------- Filter & Search ----------------
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Star filter
                DropdownButton<int?>(
                  value: _starFilter,
                  hint: const Text("Filter by stars"),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All")),
                    ...List.generate(
                      5,
                          (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Row(
                          children: List.generate(
                            i + 1,
                                (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                          ),
                        ),
                      ),
                    )
                  ],
                  onChanged: (value) {
                    setState(() {
                      _starFilter = value;
                    });
                  },
                ),
                const SizedBox(width: 20),

                // User search
                Expanded(
                  child: TextField(
                    controller: _userSearchController,
                    decoration: const InputDecoration(
                      hintText: "Search by User ID",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      setState(() {}); // rebuild when typing
                    },
                  ),
                ),
              ],
            ),
          ),

          // ---------------- Review List ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reviews yet"));
                }

                final reviews = snapshot.data!.docs
                    .where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rating = data['rating'] ?? 0;
                  final userId = data['userId'] ?? '';

                  final matchesStar = _starFilter == null || rating == _starFilter;
                  final matchesUser = _userSearchController.text.isEmpty ||
                      userId.toString().toLowerCase().contains(
                          _userSearchController.text.toLowerCase());

                  return matchesStar && matchesUser;
                })
                    .toList();

                if (reviews.isEmpty) {
                  return const Center(child: Text("No reviews match the filter"));
                }

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final doc = reviews[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final rating = data['rating'] ?? 0;
                    final comment = data['comment'] ?? '';
                    final userId = data['userId'] ?? '';
                    final paymentMethod = data['paymentMethod'] ?? '';
                    final amountPaid = data['amountPaid'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                                (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            ),
                          ),
                        ),
                        title: Text(comment.isNotEmpty ? comment : "No comment"),
                        subtitle: Text(
                            "User: $userId\nPayment: $paymentMethod\nAmount: \$${amountPaid.toStringAsFixed(2)}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteReview(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
