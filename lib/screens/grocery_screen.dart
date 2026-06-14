import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grocery_provider.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroceryProvider>(context, listen: false).fetchGroceryItems();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addCustomItem() async {
    if (!_formKey.currentState!.validate()) return;

    final groceryProvider = Provider.of<GroceryProvider>(context, listen: false);
    final success = await groceryProvider.addCustomItem(
      _nameController.text.trim(),
      _quantityController.text.trim(),
    );

    if (success && mounted) {
      _nameController.clear();
      _quantityController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddCustomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Custom Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5A36))),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Quantity (e.g. 500g, 2 packets)',
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF5A36))),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: _addCustomItem,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A36)),
            child: const Text('Add Item', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grocery = Provider.of<GroceryProvider>(context);
    final primaryColor = const Color(0xFFFF5A36);
    final surfaceColor = const Color(0xFF1E1E2C);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Grocery Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (grocery.groceryItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () => grocery.clearAllItems(),
            )
        ],
      ),
      body: grocery.isLoading && grocery.groceryItems.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A36)))
          : grocery.groceryItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: Colors.white24, size: 56),
                      const SizedBox(height: 16),
                      const Text(
                        'Your shopping checklist is empty',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Compile planner schedules to generate ingredients list.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: grocery.groceryItems.length,
                  itemBuilder: (context, idx) {
                    final item = grocery.groceryItems[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                      ),
                      child: CheckboxListTile(
                        value: item.isCompleted,
                        onChanged: (_) => grocery.toggleItemStatus(item.groceryId, item.isCompleted),
                        activeColor: primaryColor,
                        checkColor: Colors.white,
                        title: Text(
                          item.itemName,
                          style: TextStyle(
                            color: item.isCompleted ? Colors.white38 : Colors.white,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          item.quantity,
                          style: TextStyle(
                            color: item.isCompleted ? Colors.white24 : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomDialog,
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
