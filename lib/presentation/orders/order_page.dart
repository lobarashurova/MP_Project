import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/state_view.dart';
import 'package:xurmo/data/models/order_status.dart';
import 'order_detail_page.dart';
import 'widgets/order_status_widgets.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  /// Bumped to rebuild the StreamBuilder with a fresh subscription on retry.
  int _streamAttempt = 0;

  /// Order statuses follow the clock, so redraw regularly while the list is
  /// open even when Firestore sends no new data.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('My Orders'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: StateView.empty(
          icon: CupertinoIcons.person_crop_circle,
          title: 'Sign in to see your orders',
          message: 'Your order history is tied to your account.',
          actionLabel: 'Sign in',
          onAction: () => Navigator.pushNamed(context, '/login'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_streamAttempt),
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Offline or a Firestore failure — a friendly message plus a retry,
          // not a raw exception dump.
          if (snapshot.hasError) {
            return StateView.error(
              error: snapshot.error,
              onRetry: () => setState(() => _streamAttempt++),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const StateView.empty(
              icon: CupertinoIcons.bag,
              title: 'No orders yet',
              message: 'Once you place an order it will show up here.',
            );
          }

          // Sort client-side so no composite Firestore index is required for
          // the combined userId filter and createdAt ordering. An order whose
          // server timestamp has not resolved yet is the newest, so it sorts
          // first.
          final orders = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return -1;
              if (bTime == null) return 1;
              return bTime.compareTo(aTime);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final orderNumber = orders.length - index;

              return OrderCard(
                orderId: orderId,
                orderNumber: orderNumber,
                order: order,
              );
            },
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String orderId;
  final int orderNumber; // Add this
  final Map<String, dynamic> order;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final total = order['total'] ?? 0.0;
    final itemCount = (order['items'] as List?)?.length ?? 0;
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
    final status = OrderStatus.resolve(
      stored: order['status'],
      placedAt: createdAt,
      now: DateTime.now(),
    );

    final dateString = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt)
        : 'Unknown date';
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsPage(
                orderId: orderId,
                order: order,
                orderNumber: orderNumber,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #$orderNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    dateString,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              OrderStatusBadge(status: status),

              SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$itemCount items',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}