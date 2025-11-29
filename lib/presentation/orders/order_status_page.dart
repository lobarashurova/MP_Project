import 'package:flutter/material.dart';
import '../../data/repositories/local_storage_repo.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  final LocalStorageRepository _storage = LocalStorageRepository();
  Map<dynamic, dynamic>? _latestOrder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestOrder();
  }

  Future<void> _loadLatestOrder() async {
    final orders = await _storage.getOrders();
    if (orders.isNotEmpty) {
      // Get the last orders placed
      setState(() {
        _latestOrder = orders.last;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Status")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _latestOrder == null
          ? const Center(child: Text("No active orders"))
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Image/Icon
            const Icon(Icons.delivery_dining, size: 100, color: Colors.orange),
            const SizedBox(height: 20),

            const Text(
              "Your Order is on the Way!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Order ID: #${_latestOrder!['id'].toString().substring(0, 5)}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Status Steps
            _buildStatusStep("Order Received", true),
            _buildStatusStep("Preparing Food", true),
            _buildStatusStep("On the Way", true), // You can make this dynamic based on time
            _buildStatusStep("Delivered", false),

            const SizedBox(height: 40),
            Text("Total: \$${_latestOrder!['total']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String title, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: isActive ? Colors.black : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}