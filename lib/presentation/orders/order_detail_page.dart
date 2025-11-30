import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;
  final int orderNumber;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
    required this.order,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'pending';
    final total = order['total'] ?? 0.0;
    final items = (order['items'] as List?) ?? [];
    final address = order['address'] ?? 'No address';
    final phone = order['phone'] ?? 'No phone';
    final createdAt = order['createdAt']?.toDate();

    final dateString = createdAt != null
        ? DateFormat('MMMM dd, yyyy - HH:mm').format(createdAt)
        : 'Unknown date';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'processing':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
                            '\$${total.toStringAsFixed(2)}',
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
                          Text('\$2.99', style: TextStyle(fontSize: 14)),
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
                            '\$${(total + 2.99).toStringAsFixed(2)}',
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

              if (status != 'delivered' && status != 'cancelled')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
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