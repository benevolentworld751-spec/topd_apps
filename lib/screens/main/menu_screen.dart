import 'package:topd_apps/models/menu_item.dart';
import 'package:topd_apps/services/cart_service.dart';
import 'package:topd_apps/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:topd_apps/services/firestore_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    _listenForCategories();
  }

  void _listenForCategories() {
    final firestoreService =
    Provider.of<FirestoreService>(context, listen: false);

    firestoreService.getMenuItems().listen((menuItems) {
      // Safe category extraction
      final unique = menuItems
          .map((e) => e.category ?? 'Other') // <-- fixes null category
          .toSet()
          .toList();

      unique.sort();

      final List<String> newList = ['All', ...unique];

      debugPrint("Old Categories: $_categories");
      debugPrint("New Categories: $newList");

      // If categories same → no UI rebuild
      if (_categories.length == newList.length &&
          _categories.every((c) => newList.contains(c))) {
        return;
      }

      setState(() {
        _categories = newList;

        // Recreate TabController safely
        _tabController.dispose();
        _tabController =
            TabController(length: _categories.length, vsync: this);
      });
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              return StreamBuilder<List<MenuItem>>(
                stream: firestoreService.getMenuItems(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!;
                  final filtered = category == 'All'
                      ? items
                      : items.where((i) => i.category == category).toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text('No items in $category'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return MenuItemCard(item: filtered[index]);
                    },
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),

                  const SizedBox(height: 4),
                  Text(item.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$${item.price.toStringAsFixed(2)}",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold)),

                      ElevatedButton(
                        onPressed: () {
                          cartService.addItemToCart(item);

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("${item.name} added!"),
                              duration: const Duration(seconds: 1)));
                        },
                        child: const Text("Add"),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
