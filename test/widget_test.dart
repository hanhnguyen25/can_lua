import 'package:can_lua/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // App đọc cài đặt đã lưu khi mở nên cần prefs giả trong test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('mở app: có 2 tab và lưới nhập số cân', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    expect(find.text('CÀ TƯƠI'), findsOneWidget);
    expect(find.text('CÀ NHÂN'), findsOneWidget);
    expect(find.text('TÍNH TIỀN'), findsOneWidget);
    expect(find.text('PHIẾU CÂN'), findsNothing);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('nhập số cân: tổng khối và khối lượng thực cập nhật ngay', (
    tester,
  ) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '60');
    await tester.enterText(fields.at(1), '62.5');
    await tester.pumpAndSettle();

    // 60 + 62.5 = 122.5 hiện ở tổng khối và ở thanh dưới
    expect(find.text('122.5'), findsWidgets);
  });
}
