import 'package:flutter/material.dart';
import 'order_medicine_page.dart';

class CartBottomSheet extends StatelessWidget {
  final ShoppingCartService cartService;
  final MedicineOrderService orderService;
  final VoidCallback onOrderPlaced;

  const CartBottomSheet({
    Key? key,
    required this.cartService,
    required this.orderService,
    required this.onOrderPlaced,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartItems = cartService.cartItems;
    final total = cartService.calculateTotal();
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Cart',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            if (cartItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Your cart is empty',
                  style: TextStyle(fontSize: 16),
                ),
              )
            else ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return ListTile(
                      title: Text(item.medicine.name),
                      subtitle: Text('Qty: ${item.quantity}'),
                      trailing: Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Place Order'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: cartItems.isEmpty
                    ? null
                    : () async {
                        try {
                          await orderService.placeOrder('', null);
                          onOrderPlaced();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order placed!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
