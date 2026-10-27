import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xurmo/data/models/order_status.dart';
import 'widgets/order_status_widgets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_pricing.dart';
import 'package:xurmo/core/utils/haptics.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;

  /// The order as it was when the list was shown. Used until the live copy
  /// arrives from Firestore.
  final Map<String, dynamic> order;
  final int orderNumber;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.order,
    required this.orderNumber,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _orderStream;

  /// The status follows the clock, so redraw regularly while the screen is
  /// open even when the order document itself does not change.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _orderStream = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _orderStream,
      builder: (context, snapshot) {
        // Fall back to the copy from the list while loading, or if the live
        // read fails, so the screen never goes blank.
        final order = snapshot.data?.data() ?? widget.order;
        return _buildForOrder(context, order);
      },
    );
  }

  Widget _buildForOrder(BuildContext context, Map<String, dynamic> order) {
    final orderNumber = widget.orderNumber;
    final storedTotal = (order['total'] as num?)?.toDouble() ?? 0.0;
    final storedSubtotal = (order['subtotal'] as num?)?.toDouble();
    final deliveryFee =
        (order['deliveryFee'] as num?)?.toDouble() ?? AppPricing.deliveryFee;
    // Orders placed before fees were stored kept an items-only amount in
    // 'total', so treat that as the subtotal and add the fee on top.
    final subtotal = storedSubtotal ?? storedTotal;
    final total =
        storedSubtotal != null ? storedTotal : storedTotal + deliveryFee;
    final items = (order['items'] as List?) ?? [];
    final address = order['address'] ?? 'No address';
    final phone = order['phone'] ?? 'No phone';
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
    final status = OrderStatus.resolve(
      stored: order['status'],
      placedAt: createdAt,
      now: DateTime.now(),
    );
    final estimatedDelivery = OrderStatus.estimatedDelivery(
      stored: order['status'],
      placedAt: createdAt,
    );

    final dateString = createdAt != null
        ? DateFormat('MMMM dd, yyyy - HH:mm').format(createdAt)
        : 'Unknown date';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.white, // Add this line
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '#$orderNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        dateString,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 12),
                      OrderStatusBadge(status: status),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
              Text(
                'Order Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 12),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: OrderProgress(
                    status: status,
                    placedAt: createdAt,
                    estimatedDelivery: estimatedDelivery,
                  ),
                ),
              ),

              SizedBox(height: 20),
//delivery info
              Text(
                'Delivery Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),
              Card(
                color: Colors.white, // Add this line
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Divider(),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.phone, color: AppColors.primary),
                          SizedBox(width: 12),
                          Text(
                            phone,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Text(
                'Order Items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),

              ...items.map((item) => OrderItemCard(item: item)).toList(),

              SizedBox(height: 20),
//price summary
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: TextStyle(fontSize: 14)),
                          Text(
                            '\$${subtotal.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      //delivery fee
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Delivery Fee', style: TextStyle(fontSize: 14)),
                          Text('\$${deliveryFee.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Divider(),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              if (!status.isFinal)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Haptics.tap();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Need Help?'),
                          content: Text('Contact customer support at support@xurmo.com'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.help_outline, color: AppColors.primary), // Add color
                    label: Text('Need Help?', style: TextStyle(color: AppColors.primary)), // Add color
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const OrderItemCard({super.key, required this.item});
  @override
  Widget build(BuildContext context) {
    final name = item['name'] ?? 'Unknown';
    final price = item['price'] ?? 0.0;
    final quantity = item['quantity'] ?? 1;
    final image = item['image'] ?? '';

    return Card(
      color: Colors.white, // Add this line
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            //img
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image.isNotEmpty
                  ? Image.network(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.fastfood, color: Colors.grey),
                  );
                },
              )
                  : Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: Icon(Icons.fastfood, color: Colors.grey),
              ),
            ),

            SizedBox(width: 12),

            //details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Qty: $quantity',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            //price
            Text(
              '\$${(price * quantity).toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}