import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_bottom_sheet.dart';

// Abstract Base Class for Medicine (Abstraction)
abstract class Medicine {
  String get id;
  String get name;
  String get category;
  double get price;
  String get description;
  bool get requiresPrescription;
  int get stockQuantity;

  Map<String, dynamic> toJson();
  void fromJson(Map<String, dynamic> json);
  Widget buildMedicineCard(BuildContext context, VoidCallback onAddToCart);
}

// Interface for Cart Operations (Polymorphism)
mixin CartOperationsMixin {
  void addToCart(CartItem item);
  void removeFromCart(String medicineId);
  void updateQuantity(String medicineId, int quantity);
  double calculateTotal();
  void clearCart();
}

// Enum for Medicine Categories (Encapsulation)
enum MedicineCategory {
  pain('Pain Relief'),
  antibiotics('Antibiotics'),
  vitamins('Vitamins & Supplements'),
  cardiac('Cardiac Care'),
  diabetes('Diabetes'),
  respiratory('Respiratory'),
  skin('Skin Care'),
  digestive('Digestive Health');

  const MedicineCategory(this.displayName);
  final String displayName;
}

// Enum for Order Status
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  preparing('Preparing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.displayName);
  final String displayName;
}

// Medicine Model Class (Inheritance)
class PrescriptionMedicine extends Medicine {
  final String _id;
  final String _name;
  final String _category;
  final double _price;
  final String _description;
  final String _manufacturer;
  final String _composition;
  final List<String> _sideEffects;
  final String _dosage;
  final int _stockQuantity;

  PrescriptionMedicine({
    required String id,
    required String name,
    required String category,
    required double price,
    required String description,
    required String manufacturer,
    required String composition,
    required List<String> sideEffects,
    required String dosage,
    required int stockQuantity,
  }) : _id = id,
       _name = name,
       _category = category,
       _price = price,
       _description = description,
       _manufacturer = manufacturer,
       _composition = composition,
       _sideEffects = sideEffects,
       _dosage = dosage,
       _stockQuantity = stockQuantity;

  // Getters (Encapsulation)
  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get category => _category;

  @override
  double get price => _price;

  @override
  String get description => _description;

  @override
  bool get requiresPrescription => true;

  @override
  int get stockQuantity => _stockQuantity;

  String get manufacturer => _manufacturer;
  String get composition => _composition;
  List<String> get sideEffects => _sideEffects;
  String get dosage => _dosage;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _name,
      'category': _category,
      'price': _price,
      'description': _description,
      'manufacturer': _manufacturer,
      'composition': _composition,
      'sideEffects': _sideEffects,
      'dosage': _dosage,
      'stockQuantity': _stockQuantity,
      'requiresPrescription': true,
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    // Implementation for deserialization
  }

  @override
  Widget buildMedicineCard(BuildContext context, VoidCallback onAddToCart) {
    return PrescriptionMedicineCard(medicine: this, onAddToCart: onAddToCart);
  }
}

// Over-the-Counter Medicine (Inheritance)
class OTCMedicine extends Medicine {
  final String _id;
  final String _name;
  final String _category;
  final double _price;
  final String _description;
  final String _brand;
  final String _activeIngredient;
  final int _stockQuantity;

  OTCMedicine({
    required String id,
    required String name,
    required String category,
    required double price,
    required String description,
    required String brand,
    required String activeIngredient,
    required int stockQuantity,
  }) : _id = id,
       _name = name,
       _category = category,
       _price = price,
       _description = description,
       _brand = brand,
       _activeIngredient = activeIngredient,
       _stockQuantity = stockQuantity;

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get category => _category;

  @override
  double get price => _price;

  @override
  String get description => _description;

  @override
  bool get requiresPrescription => false;

  @override
  int get stockQuantity => _stockQuantity;

  String get brand => _brand;
  String get activeIngredient => _activeIngredient;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _name,
      'category': _category,
      'price': _price,
      'description': _description,
      'brand': _brand,
      'activeIngredient': _activeIngredient,
      'stockQuantity': _stockQuantity,
      'requiresPrescription': false,
    };
  }

  @override
  void fromJson(Map<String, dynamic> json) {
    // Implementation for deserialization
  }

  @override
  Widget buildMedicineCard(BuildContext context, VoidCallback onAddToCart) {
    return OTCMedicineCard(medicine: this, onAddToCart: onAddToCart);
  }
}

// Cart Item Model (Composition)
class CartItem {
  final Medicine medicine;
  int quantity;
  final DateTime addedAt;

  CartItem({
    required this.medicine,
    required this.quantity,
    required this.addedAt,
  });

  double get totalPrice => medicine.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicine.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'totalPrice': totalPrice,
    };
  }
}

// Order Model
class MedicineOrder {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime orderDate;
  final String deliveryAddress;
  final String? prescriptionImageUrl;
  final String patientId;

  MedicineOrder({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    required this.deliveryAddress,
    this.prescriptionImageUrl,
    required this.patientId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'orderDate': orderDate.toIso8601String(),
      'deliveryAddress': deliveryAddress,
      'prescriptionImageUrl': prescriptionImageUrl,
      'patientId': patientId,
    };
  }
}

// Factory Pattern for Medicine Creation
class MedicineFactory {
  static Medicine createMedicine(Map<String, dynamic> data) {
    if (data['requiresPrescription'] == true) {
      return PrescriptionMedicine(
        id: data['id'],
        name: data['name'],
        category: data['category'],
        price: data['price'].toDouble(),
        description: data['description'],
        manufacturer: data['manufacturer'] ?? '',
        composition: data['composition'] ?? '',
        sideEffects: List<String>.from(data['sideEffects'] ?? []),
        dosage: data['dosage'] ?? '',
        stockQuantity: data['stockQuantity'] ?? 0,
      );
    } else {
      return OTCMedicine(
        id: data['id'],
        name: data['name'],
        category: data['category'],
        price: data['price'].toDouble(),
        description: data['description'],
        brand: data['brand'] ?? '',
        activeIngredient: data['activeIngredient'] ?? '',
        stockQuantity: data['stockQuantity'] ?? 0,
      );
    }
  }
}

// Shopping Cart Service (Singleton Pattern)
class ShoppingCartService with CartOperationsMixin {
  static final ShoppingCartService _instance = ShoppingCartService._internal();
  factory ShoppingCartService() => _instance;
  ShoppingCartService._internal();

  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get itemCount => _cartItems.length;
  bool get isEmpty => _cartItems.isEmpty;

  @override
  void addToCart(CartItem item) {
    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.medicine.id == item.medicine.id,
    );

    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
  }

  @override
  void removeFromCart(String medicineId) {
    _cartItems.removeWhere((item) => item.medicine.id == medicineId);
  }

  @override
  void updateQuantity(String medicineId, int quantity) {
    final index = _cartItems.indexWhere(
      (item) => item.medicine.id == medicineId,
    );

    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
    }
  }

  @override
  double calculateTotal() {
    return _cartItems.fold(0.0, (total, item) => total + item.totalPrice);
  }

  @override
  void clearCart() {
    _cartItems.clear();
  }
}

// Repository Pattern for Medicine Data
abstract class MedicineRepository {
  Future<List<Medicine>> getAllMedicines();
  Future<List<Medicine>> getMedicinesByCategory(String category);
  Future<List<Medicine>> searchMedicines(String query);
  Future<Medicine?> getMedicineById(String id);
}

class FirebaseMedicineRepository implements MedicineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Medicine>> getAllMedicines() async {
    final snapshot = await _firestore.collection('medicines').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return MedicineFactory.createMedicine(data);
    }).toList();
  }

  @override
  Future<List<Medicine>> getMedicinesByCategory(String category) async {
    final snapshot = await _firestore
        .collection('medicines')
        .where('category', isEqualTo: category)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return MedicineFactory.createMedicine(data);
    }).toList();
  }

  @override
  Future<List<Medicine>> searchMedicines(String query) async {
    final snapshot = await _firestore
        .collection('medicines')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return MedicineFactory.createMedicine(data);
    }).toList();
  }

  @override
  Future<Medicine?> getMedicineById(String id) async {
    final doc = await _firestore.collection('medicines').doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return MedicineFactory.createMedicine(data);
    }
    return null;
  }
}

// Order Repository
abstract class OrderRepository {
  Future<void> createOrder(MedicineOrder order);
  Future<List<MedicineOrder>> getUserOrders(String userId);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createOrder(MedicineOrder order) async {
    await _firestore
        .collection('medicine_orders')
        .doc(order.id)
        .set(order.toJson());
  }

  @override
  Future<List<MedicineOrder>> getUserOrders(String userId) async {
    final snapshot = await _firestore
        .collection('medicine_orders')
        .where('patientId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return MedicineOrder(
        id: doc.id,
        items: (data['items'] as List)
            .map(
              (item) => CartItem(
                medicine: MedicineFactory.createMedicine(item['medicine']),
                quantity: item['quantity'],
                addedAt: DateTime.parse(item['addedAt']),
              ),
            )
            .toList(),
        totalAmount: data['totalAmount'].toDouble(),
        status: OrderStatus.values.firstWhere((s) => s.name == data['status']),
        orderDate: DateTime.parse(data['orderDate']),
        deliveryAddress: data['deliveryAddress'],
        prescriptionImageUrl: data['prescriptionImageUrl'],
        patientId: data['patientId'],
      );
    }).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('medicine_orders').doc(orderId).update({
      'status': status.name,
    });
  }
}

// Business Logic Service
class MedicineOrderService {
  final MedicineRepository _medicineRepository;
  final OrderRepository _orderRepository;
  final ShoppingCartService _cartService;

  MedicineOrderService(
    this._medicineRepository,
    this._orderRepository,
    this._cartService,
  );

  Future<List<Medicine>> getAllMedicines() async {
    return await _medicineRepository.getAllMedicines();
  }

  Future<List<Medicine>> getMedicinesByCategory(String category) async {
    return await _medicineRepository.getMedicinesByCategory(category);
  }

  Future<List<Medicine>> searchMedicines(String query) async {
    return await _medicineRepository.searchMedicines(query);
  }

  void addToCart(Medicine medicine, int quantity) {
    final cartItem = CartItem(
      medicine: medicine,
      quantity: quantity,
      addedAt: DateTime.now(),
    );
    _cartService.addToCart(cartItem);
  }

  Future<void> placeOrder(
    String deliveryAddress,
    String? prescriptionUrl,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (_cartService.isEmpty) throw Exception('Cart is empty');

    final order = MedicineOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: _cartService.cartItems,
      totalAmount: _cartService.calculateTotal(),
      status: OrderStatus.pending,
      orderDate: DateTime.now(),
      deliveryAddress: deliveryAddress,
      prescriptionImageUrl: prescriptionUrl,
      patientId: user.uid,
    );

    await _orderRepository.createOrder(order);
    _cartService.clearCart();
  }

  Future<List<MedicineOrder>> getUserOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return await _orderRepository.getUserOrders(user.uid);
  }

  // All sample/example data code removed. Only real medicines from Firestore are shown.
}

// UI Components

// Prescription Medicine Card
class PrescriptionMedicineCard extends StatelessWidget {
  final PrescriptionMedicine medicine;
  final VoidCallback onAddToCart;

  const PrescriptionMedicineCard({
    Key? key,
    required this.medicine,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.orange.shade50],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Prescription Required',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${medicine.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              medicine.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'by ${medicine.manufacturer}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicine.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.science, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    medicine.composition,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.medication, size: 16, color: Colors.purple.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dosage: ${medicine.dosage}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Stock: ${medicine.stockQuantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: medicine.stockQuantity > 10
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: medicine.stockQuantity > 0 ? onAddToCart : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// OTC Medicine Card
class OTCMedicineCard extends StatelessWidget {
  final OTCMedicine medicine;
  final VoidCallback onAddToCart;

  const OTCMedicineCard({
    Key? key,
    required this.medicine,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.blue.shade50],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OTC Available',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${medicine.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              medicine.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'by ${medicine.brand}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicine.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.science, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Active: ${medicine.activeIngredient}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Stock: ${medicine.stockQuantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: medicine.stockQuantity > 10
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: medicine.stockQuantity > 0 ? onAddToCart : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Main Order Medicine Page
class OrderMedicinePage extends StatefulWidget {
  // --- User-Driven Medicine Order Form Structure ---
  // This widget allows users to select medicines, quantity, enter address, and place an order.
  // No example/demo data is shown; all actions are user-driven and connect to Firestore.
  const OrderMedicinePage({Key? key}) : super(key: key);

  @override
  State<OrderMedicinePage> createState() => _OrderMedicinePageState();
}

class _OrderMedicinePageState extends State<OrderMedicinePage>
    with SingleTickerProviderStateMixin {
  // Add a method to show a direct order form (for single medicine quick order)
  void _showOrderMedicineForm([Medicine? selectedMedicine]) {
    final _formKey = GlobalKey<FormState>();
    Medicine? _selectedMedicine = selectedMedicine;
    int _quantity = 1;
    final _addressController = TextEditingController();
    final _prescriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Medicine'),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Medicine>(
                    value: _selectedMedicine,
                    items: _medicines.map((med) {
                      return DropdownMenuItem(
                        value: med,
                        child: Text(med.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedMedicine = val);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Select Medicine',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null ? 'Please select a medicine' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: '1',
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      if (n == null || n < 1) return 'Enter a valid quantity';
                      return null;
                    },
                    onChanged: (val) {
                      final n = int.tryParse(val);
                      if (n != null && n > 0) setState(() => _quantity = n);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter delivery address'
                        : null,
                  ),
                  if (_selectedMedicine?.requiresPrescription == true) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Prescription (text)',
                        border: OutlineInputBorder(),
                        hintText: 'Paste your prescription or enter details',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Prescription required for this medicine'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate() ||
                          _selectedMedicine == null)
                        return;
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;
                      final order = MedicineOrder(
                        id: UniqueKey().toString(),
                        items: [
                          CartItem(
                            medicine: _selectedMedicine!,
                            quantity: _quantity,
                            addedAt: DateTime.now(),
                          ),
                        ],
                        totalAmount: _selectedMedicine!.price * _quantity,
                        status: OrderStatus.pending,
                        orderDate: DateTime.now(),
                        deliveryAddress: _addressController.text.trim(),
                        prescriptionImageUrl:
                            _prescriptionController.text.trim().isNotEmpty
                            ? _prescriptionController.text.trim()
                            : null,
                        patientId: user.uid,
                      );
                      await _orderService._orderRepository.createOrder(order);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order placed successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Place Order'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  late MedicineOrderService _orderService;
  late TabController _tabController;
  late ShoppingCartService _cartService;

  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Pain Relief',
    'Antibiotics',
    'Vitamins & Supplements',
    'Cardiac Care',
    'Diabetes',
    'Respiratory',
    'Skin Care',
    'Digestive Health',
  ];

  @override
  void initState() {
    super.initState();
    _cartService = ShoppingCartService();
    _orderService = MedicineOrderService(
      FirebaseMedicineRepository(),
      FirebaseOrderRepository(),
      _cartService,
    );
    _tabController = TabController(length: 3, vsync: this);
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final medicines = await _orderService.getAllMedicines();
      if (mounted) {
        setState(() {
          _medicines = medicines;
          _filteredMedicines = medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading medicines: $e')));
      }
    }
  }

  void _filterMedicines() {
    setState(() {
      _filteredMedicines = _medicines.where((medicine) {
        final matchesCategory =
            _selectedCategory == 'All' ||
            medicine.category == _selectedCategory;
        final matchesSearch = medicine.name.toLowerCase().contains(
          _searchController.text.toLowerCase(),
        );
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Order Medicines'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Order Medicine',
            onPressed: () => _showOrderMedicineForm(),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartSheet(),
              ),
              if (_cartService.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Browse', icon: Icon(Icons.local_pharmacy)),
            Tab(text: 'Find Hospital', icon: Icon(Icons.local_hospital)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrowseTab(),
          _buildFindHospitalTab(),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search medicines...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (_) => _filterMedicines(),
              ),
              const SizedBox(height: 12),

              // Category Filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                            _filterMedicines();
                          });
                        },
                        selectedColor: Colors.green.shade100,
                        checkmarkColor: Colors.green.shade700,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Medicines List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredMedicines.isEmpty
              ? const Center(child: Text('No medicines found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = _filteredMedicines[index];
                    return medicine.buildMedicineCard(
                      context,
                      () => _addToCart(medicine),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFindHospitalTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.local_hospital, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Find Nearby Hospitals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Locate hospitals and pharmacies near you',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search Location
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter your location...',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Hospital Types
          Row(
            children: [
              Expanded(
                child: _buildHospitalTypeCard(
                  'General Hospital',
                  Icons.local_hospital,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHospitalTypeCard(
                  'Pharmacy',
                  Icons.local_pharmacy,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildHospitalTypeCard(
                  'Emergency',
                  Icons.emergency,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHospitalTypeCard(
                  'Specialist',
                  Icons.medical_services,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hospital finder feature coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Find Hospitals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalTypeCard(String title, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return FutureBuilder<List<MedicineOrder>>(
      future: _orderService.getUserOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Your medicine orders will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(MedicineOrder order) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Items: ${order.items.length}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade600,
              ),
            ),
            if (order.prescriptionImageUrl != null &&
                order.prescriptionImageUrl!.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.receipt_long, color: Colors.blueGrey, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prescription:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(order.prescriptionImageUrl!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.shipped:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  void _addToCart(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${medicine.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Price: ₹${medicine.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            if (medicine.requiresPrescription)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This medicine requires a prescription. Please have your prescription ready.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _orderService.addToCart(medicine, 1);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medicine.name} added to cart'),
                  action: SnackBarAction(
                    label: 'View Cart',
                    onPressed: _showCartSheet,
                  ),
                ),
              );
              setState(() {}); // Refresh cart badge
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Add to Cart',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CartBottomSheet(
        cartService: _cartService,
        orderService: _orderService,
        onOrderPlaced: () {
          setState(() {}); // Refresh UI
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Cart Bottom Sheet
