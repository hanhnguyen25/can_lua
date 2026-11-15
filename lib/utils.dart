import 'package:flutter/material.dart';

// ---------- Màu sắc ----------
const kBlue = Color(0xFF2196F3); // Cà tươi
const kBlueDark = Color(0xFF1565C0);
const kGreen = Color(0xFF43A047); // Cà nhân
const kGreenDark = Color(0xFF2E7D32);
const kNavy = Color(0xFF0B4F8A);
const kPink = Color(0xFFFFDADA);
const kBg = Color(0xFFF0F2F7);
const kPurple = Color(0xFF9C27B0);
const kOrange = Color(0xFFF59E0B);
const kRed = Color(0xFFF44336);

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
