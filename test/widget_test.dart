import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viora/main.dart';
import 'package:viora/services/storage_service.dart';

void main() {
  testWidgets('VioraApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
    await tester.pumpWidget(const VioraApp());
    expect(find.byType(VioraApp), findsOneWidget);
  });
}
