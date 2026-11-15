import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:excel/excel.dart' as xl;
import 'package:file_selector/file_selector.dart' hide XFile;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';
import 'storage.dart';
import 'utils.dart';
import 'web_download.dart';

Future<File> _tempFile(String name) async {
  final dir = await getTemporaryDirectory();
  return File('${dir.path}/$name');
}

/// Trên web: tải file thẳng xuống máy. Trên Android/iOS: chia sẻ như cũ.
Future<void> _luuHoacChiaSe(
  Uint8List bytes,
  String fileName,
  String mime,
) async {
  if (kIsWeb) {
    taiFile(bytes, fileName, mime);
    return;
  }
  final file = await _tempFile(fileName);
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}

double _r2(double v) => double.parse(v.toStringAsFixed(2));

// ---------- Chia sẻ ảnh phiếu (gửi Zalo, Messenger...) ----------
Future<void> shareWidgetImage(GlobalKey key, String name) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return;
  final ui.Image image = await boundary.toImage(pixelRatio: 3);
  final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) return;
  await _luuHoacChiaSe(data.buffer.asUint8List(), '$name.png', 'image/png');
}

// ---------- Xuất Excel (.xlsx) ----------
Future<void> shareExcel(List<Ticket> tickets, {String label = 'tat_ca'}) async {
  final excel = xl.Excel.createExcel();
  final sheet = excel['Sheet1'];

  sheet.appendRow([
    for (final h in [
      'Ngày giờ',
      'Loại',
      'Khách hàng',
      'Ghi chú',
      'Số mạ',
      'Tổng cân (kg)',
      'Trừ bì (kg)',
      'Độ ẩm (%)',
      'Trừ độ (kg)',
      'Trừ tạp (kg)',
      'Khối lượng thực (kg)',
      'Đơn giá (đ/kg)',
      'Thành tiền (đ)',
    ])
      xl.TextCellValue(h),
  ]);

  final sorted = [...tickets]..sort((a, b) => a.time.compareTo(b.time));
  for (final t in sorted) {
    final c = t.calc;
    sheet.appendRow([
      xl.TextCellValue(fmtDateTime(t.time)),
      xl.TextCellValue(kindNames[t.kind]),
      xl.TextCellValue(t.customer),
      xl.TextCellValue(t.note),
      xl.IntCellValue(c.bags),
      xl.DoubleCellValue(_r2(c.gross)),
      xl.DoubleCellValue(_r2(c.tareTotal)),
      xl.DoubleCellValue(_r2(t.doAm)),
      xl.DoubleCellValue(_r2(c.doKg)),
      xl.DoubleCellValue(_r2(c.tapKg)),
      xl.DoubleCellValue(_r2(c.net)),
      xl.DoubleCellValue(_r2(t.price)),
      xl.IntCellValue(c.amount.round()),
    ]);
  }

  final bytes = excel.save();
  if (bytes == null) throw Exception('Không tạo được file Excel');
  await _luuHoacChiaSe(
    Uint8List.fromList(bytes),
    'phieu_can_${label}_${stamp(DateTime.now())}.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}

// ---------- Sao lưu (file .json) ----------
Future<void> shareBackup(List<Ticket> tickets) async {
  final json = const JsonEncoder.withIndent('  ').convert({
    'app': 'can_ca_phe',
    'version': 1,
    'tickets': tickets.map((t) => t.toJson()).toList(),
  });
  await _luuHoacChiaSe(
    Uint8List.fromList(utf8.encode(json)),
    'sao_luu_can_${stamp(DateTime.now())}.json',
    'application/json',
  );
}

// ---------- Khôi phục từ file sao lưu ----------
// Trả về số phiếu thêm mới, hoặc null nếu người dùng không chọn file
Future<int?> restoreBackup() async {
  final f = await openFile();
  if (f == null) return null;
  final data = jsonDecode(await f.readAsString());
  final rawList = data is Map ? data['tickets'] : data;
  final list = (rawList as List)
      .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
  return TicketStore.merge(list);
}
