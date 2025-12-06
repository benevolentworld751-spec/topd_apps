import 'package:flutter/material.dart';

class ReviewDialog extends StatefulWidget {
  final Function(double rating, String feedback) onSubmit;

  const ReviewDialog({super.key, required this.onSubmit});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double rating = 5;
  final TextEditingController feedbackController = TextEditingController();

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rate Your Experience"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (index) => IconButton(
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() => rating = index + 1.0);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: feedbackController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Leave a comment (optional)",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(rating, feedbackController.text.trim());
            Navigator.pop(context);
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}

