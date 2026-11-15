import 'package:can_lua/do_am_ca_phe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bảng trừ độ ẩm', () {
    test('bảng có 10 hàng × 10 cột', () {
      expect(bangTruDoAm.length, 10);
      for (final hang in bangTruDoAm) {
        expect(hang.length, 10);
      }
    });

    test('đúng các ô đã in trên bảng giấy', () {
      expect(traCuuPhanTramTru(15.0), 0.00);
      expect(traCuuPhanTramTru(15.5), 0.57);
      expect(traCuuPhanTramTru(16.5), 1.68);
      expect(traCuuPhanTramTru(17.2), 2.57);
      expect(traCuuPhanTramTru(19.4), 5.83);
      expect(traCuuPhanTramTru(20.0), 6.95);
      expect(traCuuPhanTramTru(21.4), 9.73);
      expect(traCuuPhanTramTru(23.9), 16.13);
      expect(traCuuPhanTramTru(24.9), 19.15);
      expect(traCuuPhanTramTru(25.0), 19.47);
    });

    test('không trừ khi độ ẩm ≤ 15', () {
      expect(phanTramTruTheoDoAm(0), 0);
      expect(phanTramTruTheoDoAm(14.9), 0);
      expect(phanTramTruTheoDoAm(15.0), 0);
    });

    test('làm tròn đến 0,1% trước khi tra', () {
      expect(phanTramTruTheoDoAm(15.54), 0.57);
      expect(phanTramTruTheoDoAm(16.05), 1.24);
      expect(phanTramTruTheoDoAm(17.24), 2.57);
    });

    test('vượt 25 độ thì lấy mức tối đa', () {
      expect(phanTramTruTheoDoAm(25.1), phanTramTruToiDa);
      expect(phanTramTruTheoDoAm(30), phanTramTruToiDa);
      expect(tinhTruDoAm(khoiLuongKg: 100, doAm: 26).vuotBang, isTrue);
      expect(tinhTruDoAm(khoiLuongKg: 100, doAm: 25).vuotBang, isFalse);
    });

    test('quy ra kg: 100 kg độ ẩm 15,5 trừ 0,57 kg (5,7 lạng)', () {
      final kq = tinhTruDoAm(khoiLuongKg: 100, doAm: 15.5);
      expect(kq.phanTramTru, 0.57);
      expect(kq.khoiLuongTru, closeTo(0.57, 1e-9));
      expect(kq.khoiLuongTruLang, closeTo(5.7, 1e-9));
      expect(kq.khoiLuongConLai, closeTo(99.43, 1e-9));
    });

    test('1.000 kg độ ẩm 15,5 trừ 5,70 kg', () {
      final kq = tinhTruDoAm(khoiLuongKg: 1000, doAm: 15.5);
      expect(kq.khoiLuongTru, closeTo(5.7, 1e-9));
      expect(kq.khoiLuongConLai, closeTo(994.3, 1e-9));
    });

    test('đơn điệu: cùng hàng và cùng cột đều tăng dần', () {
      for (var h = 0; h < bangTruDoAm.length; h++) {
        for (var c = 1; c < 10; c++) {
          expect(
            bangTruDoAm[h][c],
            greaterThan(bangTruDoAm[h][c - 1]),
            reason: 'hàng ${h + 15}, cột 0,$c',
          );
        }
      }
    });
  });
}
