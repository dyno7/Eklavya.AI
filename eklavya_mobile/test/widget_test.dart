import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eklavya_mobile/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EklavyaApp()),
    );
    // Just verify app builds without crashing
    expect(find.text('Eklavya.AI'), findsOneWidget);
  });
}
