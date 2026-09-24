import 'package:flutter_test/flutter_test.dart';
import 'package:nova_mobile/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('NOVA onboarding açılıyor', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NovaApp());
    await tester.pumpAndSettle();
    expect(find.text('Herkes aynı yerden başlar.'), findsOneWidget);
  });
}
