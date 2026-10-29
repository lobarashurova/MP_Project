import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/data/models/order_status.dart';

/// Colour used for a status everywhere in the app.
Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Colors.orange;
    case OrderStatus.preparing:
      return Colors.blue;
    case OrderStatus.onTheWay:
      return Colors.deepPurple;
    case OrderStatus.delivered:
      return Colors.green;
    case OrderStatus.cancelled:
      return Colors.red;
  }
}

/// Small rounded label with the status name, used on the order list and the
/// order detail screen.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

/// Step-by-step view of where the order is: Pending, Preparing, On the way,
/// Delivered. Shows the expected delivery time while the order is moving.
class OrderProgress extends StatelessWidget {
  final OrderStatus status;
  final DateTime? placedAt;
  final DateTime? estimatedDelivery;

  const OrderProgress({
    super.key,
    required this.status,
    this.placedAt,
    this.estimatedDelivery,
  });

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return const Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text('This order was cancelled.')),
        ],
      );
    }

    final time = DateFormat('HH:mm');
    final steps = OrderStatus.progression;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            label: steps[i].label,
            time: placedAt == null ? null : time.format(placedAt!.add(steps[i].startsAfter!)),
            done: i < status.step,
            current: i == status.step,
            isLast: i == steps.length - 1,
            color: orderStatusColor(steps[i]),
          ),
        if (!status.isFinal && estimatedDelivery != null) ...[
          const SizedBox(height: 8),
          Text(
            'Expected delivery by ${time.format(estimatedDelivery!)}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final String? time;
  final bool done;
  final bool current;
  final bool isLast;
  final Color color;

  const _StepRow({
    required this.label,
    required this.time,
    required this.done,
    required this.current,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reached = done || current;
    final dotColor = reached ? color : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                child: Icon(
                  done ? Icons.check : (current ? Icons.circle : null),
                  size: done ? 14 : 8,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? color : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: current ? FontWeight.bold : FontWeight.normal,
                        color: reached ? AppColors.iconPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (time != null)
                    Text(time!, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
