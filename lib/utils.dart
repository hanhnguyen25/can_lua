import 'package:flutter/material.dart';

// ---------- Màu sắc ----------
// Mỗi phần có một màu nhận diện riêng: xanh dương = Cà tươi, xanh lá = Cà nhân.
// Các màu đã được làm đậm để chữ trắng đạt tương phản AA trên nền màu.
const kBlue = Color(0xFF0B5FA5); // Cà tươi
const kBlueDark = Color(0xFF084A80);
const kGreen = Color(0xFF166B4A); // Cà nhân
const kGreenDark = Color(0xFF0E4F36);

const kNavy = Color(0xFF10293A); // số liệu chính
const kInk = Color(0xFF12232F); // chữ chính
const kInk2 = Color(0xFF51636F); // chữ phụ (4.9:1 trên nền trắng, 4.3:1 trên nền xám)
const kLine = Color(0xFFDCE5EE); // đường kẻ mảnh
const kSurface = Color(0xFFFFFFFF);
const kBg = Color(0xFFEDF1F6); // nền chung
const kTint = Color(0xFFF4F7FA); // nền ô nhập khi còn trống

const kPink = Color(0xFFFFF3E8); // nền ghi chú nhẹ
const kPurple = Color(0xFF10293A); // tổng khối
const kOrange = Color(0xFFB45309); // tiền (đạt 4.6:1 trên nền trắng)
const kRed = Color(0xFFB3261E);

const kindNames = ['Cà tươi', 'Cà nhân'];
Color kindColor(int kind) => kind == 1 ? kGreen : kBlue;
Color kindDark(int kind) => kind == 1 ? kGreenDark : kBlueDark;

// ---------- Số ----------
double parseNumber(String s) =>
    double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;

String fmtKg(double v) => v.toStringAsFixed(1);

// Số cân hiển thị gọn: 60 -> "60", 62.5 -> "62.5"
String fmtNum(double v) {
  var s = v.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}

String fmtPct(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  if ((v * 10) == (v * 10).roundToDouble()) return v.toStringAsFixed(1);
  return v.toStringAsFixed(2);
}

String fmtMoney(double v) => v.round().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (m) => '.',
);

// ---------- Ngày giờ ----------
String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
String fmtDateTime(DateTime d) =>
    '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';
String stamp(DateTime d) =>
    '${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}';
