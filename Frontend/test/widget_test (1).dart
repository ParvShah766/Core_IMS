import 'package:flutter_test/flutter_test.dart';

import 'package:core_ims/app/app.dart';

void main() {
  testWidgets('App opens on login screen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CoreImsApp());

    expect(find.text('Core IMS Login'), findsOneWidget);
    expect(find.text('Sign in to manage stock operations.'), findsOneWidget);
  });
}
