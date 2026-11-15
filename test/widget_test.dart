import 'package:can_lua/main.dart';
import 'package:can_lua/models.dart';
import 'package:can_lua/receipt_screen.dart';
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

  testWidgets('chữ nhỏ hơn 10% so với cài đặt máy', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(MediaQuery.of(context).textScaler.scale(10), closeTo(9, 1e-9));
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

  testWidgets('lưu phiếu xong: số cân và cài đặt đều về 0', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '60');
    await tester.pumpAndSettle();

    // Nhập đơn giá 20000
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();
    final oGia = find.ancestor(
      of: find.text('Đơn giá (đ/kg)'),
      matching: find.byType(TextField),
    );
    await tester.enterText(oGia, '20000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();

    // Tính tiền rồi lưu phiếu
    await tester.tap(find.text('TÍNH TIỀN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu phiếu'));
    await tester.pumpAndSettle();

    // Ô số cân đã trống
    final oDau = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(oDau.controller!.text, '');

    // Cài đặt cũng về 0
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();

    final gia = tester.widget<TextField>(
      find.ancestor(
        of: find.text('Đơn giá (đ/kg)'),
        matching: find.byType(TextField),
      ),
    );
    final bi = tester.widget<TextField>(
      find.ancestor(
        of: find.text('Bì mỗi bao (kg)'),
        matching: find.byType(TextField),
      ),
    );
    expect(gia.controller!.text, '');
    expect(bi.controller!.text, '');
  });

  testWidgets('phiếu đã lưu: sửa độ ẩm thì tính lại tiền', (tester) async {
    final t = Ticket(
      id: 't1',
      kind: 1,
      customer: 'A',
      note: '',
      time: DateTime(2026, 1, 1, 8),
      cells: [1000, 0, 0, 0, 0],
      tarePerBag: 0,
      tareBags: 0,
      doPct: 0.57,
      doAm: 15.5,
      tapPct: 0,
      price: 10000,
    );

    await tester.pumpWidget(
      MaterialApp(home: ReceiptScreen(ticket: t, isDraft: false)),
    );
    await tester.pumpAndSettle();

    // 1000 kg, trừ 0,57% → 5,7 kg làm tròn 6 kg → 994 kg × 10.000 = 9.940.000
    expect(find.text('9.940.000 đ'), findsOneWidget);
    // Thành tiền chỉ hiển thị, không phải ô nhập
    expect(
      find.ancestor(
        of: find.text('Thành tiền (đ)'),
        matching: find.byType(TextField),
      ),
      findsNothing,
    );

    final oDoAm = find.ancestor(
      of: find.text('Độ ẩm (%)'),
      matching: find.byType(TextField),
    );
    await tester.enterText(oDoAm, '17,2');
    await tester.pumpAndSettle();

    // 17,2 độ → 2,57% → 25,7 kg làm tròn 26 kg → 974 kg × 10.000
    expect(find.text('9.740.000 đ'), findsOneWidget);
    expect(t.doPct, closeTo(2.57, 1e-9));
    expect(t.doAm, closeTo(17.2, 1e-9));
  });

  testWidgets('màn hình hẹp, số lớn vẫn không tràn cột', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await tester.enterText(find.byType(TextField).at(i), '9999');
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('nhập đủ 2 số tự xuống ô kế tiếp', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '60');
    await tester.pump(const Duration(milliseconds: 600));

    final oThu2 = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(oThu2.focusNode!.hasFocus, isTrue);
  });

  testWidgets('nhập 3 số thì chưa nhảy khi cài 2 số', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '605');
    await tester.pump(const Duration(milliseconds: 600));

    final oThu2 = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(oThu2.focusNode!.hasFocus, isFalse);
  });

  testWidgets('gõ số thập phân 62,5 thì không nhảy sớm', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '62');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField).at(0), '62,5');
    await tester.pump(const Duration(milliseconds: 600));

    final oThu2 = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(oThu2.focusNode!.hasFocus, isFalse);
  });

  testWidgets('cài đặt chỉ hiển thị số mạ đã nhập', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    // Cân 2 bao
    await tester.enterText(find.byType(TextField).at(0), '60');
    await tester.enterText(find.byType(TextField).at(1), '61,5');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();

    // Không có ô nhập, chỉ hiện số mạ đếm được
    expect(find.text('Số mạ đã nhập: 2'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('Số mạ'), matching: find.byType(TextField)),
      findsNothing,
    );
  });

  testWidgets('cà nhân: nhập độ ẩm 15,5 tự trừ độ 0,57%', (tester) async {
    await tester.pumpWidget(const CanApp());
    await tester.pumpAndSettle();

    // Sang phần Cà nhân
    await tester.tap(find.text('CÀ NHÂN'));
    await tester.pumpAndSettle();

    // Cân 1 bao 1000 kg
    await tester.enterText(find.byType(TextField).first, '1000');
    await tester.pumpAndSettle();

    // Mở Cài đặt để nhập độ ẩm
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cài đặt'));
    await tester.pumpAndSettle();

    final oDoAm = find.ancestor(
      of: find.text('Độ ẩm (%)'),
      matching: find.byType(TextField),
    );
    await tester.enterText(oDoAm, '15,5');
    await tester.pumpAndSettle();

    // 15,5 độ → trừ 0,57% → 1000 kg trừ 5,7 kg, làm tròn 6 kg
    expect(find.textContaining('Trừ độ 0.57%'), findsOneWidget);
    expect(find.textContaining('6.0 kg'), findsOneWidget);
  });
}
