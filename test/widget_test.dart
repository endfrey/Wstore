import 'package:flutter_test/flutter_test.dart';
import 'package:wstore/main.dart'; // 

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // ตรวจสอบ widget เบื้องต้น เช่น มี text Hello WStore
    expect(find.text('Hello WStore'), findsOneWidget);
  });
}
