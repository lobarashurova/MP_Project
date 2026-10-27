import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/data/models/order_status.dart';

void main() {
  final placedAt = DateTime(2026, 10, 26, 12, 0);
  OrderStatus at(Duration elapsed, {Object? stored = 'pending'}) =>
      OrderStatus.resolve(stored: stored, placedAt: placedAt, now: placedAt.add(elapsed));

  group('OrderStatus.resolve follows the clock for a new order', () {
    test('starts as pending', () {
      expect(at(Duration.zero), OrderStatus.pending);
      expect(at(const Duration(minutes: 1, seconds: 59)), OrderStatus.pending);
    });

    test('is preparing from 2 minutes', () {
      expect(at(const Duration(minutes: 2)), OrderStatus.preparing);
      expect(at(const Duration(minutes: 9, seconds: 59)), OrderStatus.preparing);
    });

    test('is on the way from 10 minutes', () {
      expect(at(const Duration(minutes: 10)), OrderStatus.onTheWay);
      expect(at(const Duration(minutes: 24)), OrderStatus.onTheWay);
    });

    test('is delivered from 25 minutes and stays delivered', () {
      expect(at(const Duration(minutes: 25)), OrderStatus.delivered);
      expect(at(const Duration(days: 3)), OrderStatus.delivered);
    });

    test('treats a missing stored status like pending', () {
      expect(at(const Duration(minutes: 12), stored: null), OrderStatus.onTheWay);
    });

    test('is pending when the server time has not arrived yet', () {
      expect(
        OrderStatus.resolve(stored: 'pending', placedAt: null, now: placedAt),
        OrderStatus.pending,
      );
    });

    test('is pending if the device clock is behind the order time', () {
      expect(at(const Duration(minutes: -5)), OrderStatus.pending);
    });
  });

  group('a stored status always wins', () {
    test('a cancelled order stays cancelled', () {
      expect(at(const Duration(hours: 1), stored: 'cancelled'), OrderStatus.cancelled);
    });

    test('a status set by an admin is not overridden by the clock', () {
      expect(at(const Duration(minutes: 30), stored: 'preparing'), OrderStatus.preparing);
      expect(at(Duration.zero, stored: 'delivered'), OrderStatus.delivered);
    });
  });

  group('OrderStatus.fromStorage', () {
    test('reads the current values', () {
      for (final status in OrderStatus.values) {
        expect(OrderStatus.fromStorage(status.storageValue), status);
      }
    });

    test('reads spellings used by older versions of the app', () {
      expect(OrderStatus.fromStorage('processing'), OrderStatus.preparing);
      expect(OrderStatus.fromStorage('On the way'), OrderStatus.onTheWay);
      expect(OrderStatus.fromStorage('canceled'), OrderStatus.cancelled);
      expect(OrderStatus.fromStorage('COMPLETED'), OrderStatus.delivered);
    });

    test('returns null for unknown or missing values', () {
      expect(OrderStatus.fromStorage('lost'), isNull);
      expect(OrderStatus.fromStorage(null), isNull);
      expect(OrderStatus.fromStorage(42), isNull);
    });

    test('an unknown stored value falls back to the clock', () {
      expect(at(const Duration(minutes: 3), stored: 'lost'), OrderStatus.preparing);
    });
  });

  group('OrderStatus.estimatedDelivery', () {
    test('is 25 minutes after the order while it follows the clock', () {
      expect(
        OrderStatus.estimatedDelivery(stored: 'pending', placedAt: placedAt),
        placedAt.add(const Duration(minutes: 25)),
      );
    });

    test('is not shown for an order with an explicit status', () {
      expect(OrderStatus.estimatedDelivery(stored: 'cancelled', placedAt: placedAt), isNull);
    });

    test('is not shown before the order time is known', () {
      expect(OrderStatus.estimatedDelivery(stored: 'pending', placedAt: null), isNull);
    });
  });

  test('progression lists the normal path in order, without cancelled', () {
    expect(OrderStatus.progression.map((s) => s.step), [0, 1, 2, 3]);
    expect(OrderStatus.cancelled.step, -1);
    expect(OrderStatus.delivered.isFinal, isTrue);
    expect(OrderStatus.onTheWay.isFinal, isFalse);
  });
}
