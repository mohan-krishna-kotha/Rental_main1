import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rental_app/main.dart';

void main() {
  testWidgets('App bootstraps with ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // AuthGate should render either loading/auth/main shell based on auth state.
    expect(find.byType(AuthGate), findsOneWidget);
  });
}
