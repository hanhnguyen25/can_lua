/// Bảng trừ trọng lượng cà phê nhân xô theo độ ẩm.
///
/// Bảng gốc: "BẢNG TRỪ TRỌNG LƯỢNG CÀ PHÊ NHÂN XÔ CÓ ĐỘ ẨM VƯỢT TRÊN 15 ĐỘ".
/// - Hàng: phần nguyên của độ ẩm (15 → 25).
/// - Cột: phần lẻ 0,1 của độ ẩm (0,0 → 0,9).
/// - Ô: phần trăm trọng lượng bị trừ (tính trên 100 kg).
library;

/// Độ ẩm bắt đầu bị trừ (%).
const double doAmKhongTru = 15.0;

/// Độ ẩm cao nhất có trong bảng (%).
const double doAmToiDaTraBang = 25.0;

/// Mức trừ cao nhất trong bảng (ô 25,0).
const double phanTramTruToiDa = 19.47;

/// Bảng trừ: 10 hàng ứng với độ ẩm 15 → 24 (mỗi hàng 10 ô phần lẻ 0,0 → 0,9).
/// Riêng độ ẩm 25,0 = 19,47%; các mức 25,1 → 25,9 không có trong bảng.
///
/// Lưu ý: ô 19,4 và 21,4 in trên bảng giấy là 5,83 và 9,73, lệch quy luật tăng
/// dần (đáng lẽ 5,88 và 9,78). Giữ đúng số in; sửa 2 ô này nếu cần.
const List<List<double>> bangTruDoAm = <List<double>>[
  <double>[0.00, 0.10, 0.20, 0.37, 0.47, 0.57, 0.67, 0.77, 0.88, 0.99], // 15
  <double>[1.13, 1.24, 1.35, 1.46, 1.57, 1.68, 1.80, 1.92, 2.04, 2.16], // 16
  <double>[2.31, 2.44, 2.57, 2.70, 2.83, 2.96, 3.10, 3.24, 3.38, 3.52], // 17
  <double>[3.67, 3.81, 3.96, 4.11, 4.26, 4.41, 4.56, 4.71, 4.87, 5.03], // 18
  <double>[5.20, 5.37, 5.54, 5.71, 5.83, 6.05, 6.23, 6.41, 6.59, 6.77], // 19
  <double>[6.95, 7.13, 7.32, 7.51, 7.71, 7.91, 8.11, 8.31, 8.51, 8.71], // 20
  <double>[8.91, 9.12, 9.34, 9.56, 9.73, 10.00, 10.22, 10.44, 10.67, 10.90], // 21
  <double>[11.13, 11.36, 11.60, 11.85, 12.10, 12.35, 12.60, 12.85, 13.10, 13.36], // 22
  <double>[13.62, 13.88, 14.15, 14.43, 14.71, 14.99, 15.27, 15.55, 15.84, 16.13], // 23
  <double>[16.42, 16.70, 17.01, 17.31, 17.61, 17.91, 18.22, 18.53, 18.84, 19.15], // 24
];

/// Tra tỷ lệ trừ (%) theo độ ẩm, đã làm tròn đến 0,1%.
///
/// Trả về 0 khi độ ẩm ≤ 15,0; trả về 19,47 khi độ ẩm ≥ 25,0; trả về null nếu
/// giá trị âm hoặc không hợp lệ.
double? traCuuPhanTramTru(double doAm) {
  if (doAm.isNaN || doAm < 0) return null;
  if (doAm <= doAmKhongTru) return 0.0;

  final phanMuoi = (doAm * 10).round(); // 15,5 → 155
  if (phanMuoi >= 250) return phanTramTruToiDa;

  final hang = phanMuoi ~/ 10;
  final cot = phanMuoi % 10;
  return bangTruDoAm[hang - 15][cot];
}

/// Tỷ lệ trừ (%) theo độ ẩm, dùng trực tiếp cho công thức tính tiền.
double phanTramTruTheoDoAm(double doAm) => traCuuPhanTramTru(doAm) ?? 0.0;

/// Kết quả tính trừ độ ẩm cho một lô cà phê.
class KetQuaTruDoAm {
  const KetQuaTruDoAm({
    required this.khoiLuongNhap,
    required this.doAmNhap,
    required this.doAmApDung,
    required this.phanTramTru,
    required this.khoiLuongTru,
    required this.khoiLuongConLai,
    required this.vuotBang,
  });

  final double khoiLuongNhap;
  final double doAmNhap;
  final double doAmApDung;
  final double phanTramTru;
  final double khoiLuongTru;
  final double khoiLuongConLai;
  final bool vuotBang;

  double get khoiLuongTruLang => khoiLuongTru * 10;
}

/// Tính phần trọng lượng bị trừ do độ ẩm vượt 15 độ.
KetQuaTruDoAm tinhTruDoAm({
  required double khoiLuongKg,
  required double doAm,
}) {
  final doAmApDung = (doAm * 10).roundToDouble() / 10;
  final phanTram = phanTramTruTheoDoAm(doAmApDung);
  final khoiLuongTru = _lamTron(khoiLuongKg * phanTram / 100, 2);

  return KetQuaTruDoAm(
    khoiLuongNhap: khoiLuongKg,
    doAmNhap: doAm,
    doAmApDung: doAmApDung,
    phanTramTru: phanTram,
    khoiLuongTru: khoiLuongTru,
    khoiLuongConLai: _lamTron(khoiLuongKg - khoiLuongTru, 2),
    vuotBang: doAmApDung > doAmToiDaTraBang,
  );
}

double _lamTron(double giaTri, int soLe) {
  final heSo = _luyThua10(soLe);
  return (giaTri * heSo).roundToDouble() / heSo;
}

double _luyThua10(int soMu) {
  var ketQua = 1.0;
  for (var i = 0; i < soMu; i++) {
    ketQua *= 10;
  }
  return ketQua;
}
