import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the decision to drop every bottom-anchored toast.
///
/// Feedback belongs inline, in the state of the thing the user touched, not in
/// a bar that slides over the nav. A source scan is the only way to catch a
/// reintroduction, since a SnackBar nobody shows is invisible to widget tests.
void main() {
  test('no SnackBar or ScaffoldMessenger anywhere under lib/', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('SnackBar') || line.contains('ScaffoldMessenger')) {
          offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Bottom toasts were removed on purpose. Show this feedback '
          'inline instead:\n${offenders.join('\n')}',
    );
  });
}
