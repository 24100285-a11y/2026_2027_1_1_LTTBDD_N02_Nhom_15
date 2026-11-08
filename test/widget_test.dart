import 'package:flutter_test/flutter_test.dart';
import 'package:hoc_tot/app/app.dart';

void main() {
  testWidgets('Học Tốt app starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const HocTotApp());

    expect(find.text('Học Tốt'), findsOneWidget);
  });
}
