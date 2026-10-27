/// The stages an order goes through, in order.
///
/// Until couriers and restaurants have their own screens, nobody updates the
/// status in the database. For the demo, the status is therefore worked out
/// from how long ago the order was placed (see [OrderStatus.resolve]). A
/// status that is explicitly saved on the order, such as `cancelled` or a
/// value set by an admin, always wins over the calculated one.
enum OrderStatus {
  pending('pending', 'Pending'),
  preparing('preparing', 'Preparing'),
  onTheWay('on_the_way', 'On the way'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.storageValue, this.label);

  /// Value stored in the order's `status` field in Firestore.
  final String storageValue;

  /// Text shown to the customer.
  final String label;

  /// True once the order can no longer change.
  bool get isFinal => this == delivered || this == cancelled;

  /// The normal path an order takes. Cancelled is not part of it.
  static const List<OrderStatus> progression = [pending, preparing, onTheWay, delivered];

  /// Position on [progression], or -1 for cancelled.
  int get step => progression.indexOf(this);

  // ------------------------------------------------------------- Timing

  /// How long after placing the order each stage starts.
  static const Duration preparingAfter = Duration(minutes: 2);
  static const Duration onTheWayAfter = Duration(minutes: 10);
  static const Duration deliveredAfter = Duration(minutes: 25);

  /// When this stage starts, counted from when the order was placed.
  /// Null for cancelled, which has no fixed time.
  Duration? get startsAfter {
    switch (this) {
      case pending:
        return Duration.zero;
      case preparing:
        return preparingAfter;
      case onTheWay:
        return onTheWayAfter;
      case delivered:
        return deliveredAfter;
      case cancelled:
        return null;
    }
  }

  // ------------------------------------------------------------ Parsing

  /// Reads a stored status. Returns null for a missing or unknown value.
  ///
  /// Accepts the spellings older versions of the app used, such as
  /// `processing` and `on the way`.
  static OrderStatus? fromStorage(Object? value) {
    if (value is! String) return null;
    switch (value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_')) {
      case 'pending':
        return pending;
      case 'preparing':
      case 'processing':
        return preparing;
      case 'on_the_way':
      case 'ontheway':
      case 'delivering':
        return onTheWay;
      case 'delivered':
      case 'completed':
        return delivered;
      case 'cancelled':
      case 'canceled':
        return cancelled;
      default:
        return null;
    }
  }

  /// Works out what the customer should see right now.
  ///
  /// - A stored status other than `pending` is an explicit decision and is
  ///   returned as-is.
  /// - Otherwise the status follows the clock from [placedAt]. An order whose
  ///   time is not known yet, because the server timestamp has not arrived,
  ///   counts as pending.
  static OrderStatus resolve({
    Object? stored,
    DateTime? placedAt,
    required DateTime now,
  }) {
    final explicit = fromStorage(stored);
    if (explicit != null && explicit != pending) return explicit;
    if (placedAt == null) return pending;

    final elapsed = now.difference(placedAt);
    if (elapsed >= deliveredAfter) return delivered;
    if (elapsed >= onTheWayAfter) return onTheWay;
    if (elapsed >= preparingAfter) return preparing;
    return pending;
  }

  /// Expected delivery time for an order that is still following the clock,
  /// or null when it does not apply.
  static DateTime? estimatedDelivery({Object? stored, DateTime? placedAt}) {
    final explicit = fromStorage(stored);
    if (placedAt == null) return null;
    if (explicit != null && explicit != pending) return null;
    return placedAt.add(deliveredAfter);
  }
}
