import 'package:flutter/material.dart';

import 'utils.dart';

// ---------- Một khối cân: 5 cột x 5 hàng = 25 ô ----------
class Block {
  static const cols = 5;
  static const rows = 5;
  static const size = cols * rows;

  final List<TextEditingController> ctrls = List.generate(
    size,
    (_) => TextEditingController(),
  );
  final List<FocusNode> nodes = List.generate(size, (_) => FocusNode());
  bool collapsed = false;

  // Ô thứ i nằm ở cột i ~/ 5, hàng i % 5 (nhập hết cột này mới sang cột sau)
  double _value(int i) {
    final v = parseNumber(ctrls[i].text);
    return v > 0 ? v : 0;
  }

  List<double> get values => List.generate(size, _value);

  double colTotal(int c) {
    double sum = 0;
    for (int r = 0; r < rows; r++) {
      sum += _value(c * rows + r);
    }
    return sum;
  }

  double get total {
    double sum = 0;
    for (int i = 0; i < size; i++) {
      sum += _value(i);
    }
    return sum;
  }

  int get count {
    int n = 0;
    for (int i = 0; i < size; i++) {
      if (_value(i) > 0) n++;
    }
    return n;
  }

  // Cột cuối cùng (cột thứ 5) đã nhập đủ 5 ô
  bool get lastColFull {
    for (int r = 0; r < rows; r++) {
      if (_value((cols - 1) * rows + r) <= 0) return false;
    }
    return true;
  }

  void dispose() {
    for (final c in ctrls) {
      c.dispose();
    }
    for (final n in nodes) {
      n.dispose();
    }
  }
}

// ---------- Công thức tính (dùng chung cho màn hình cân và phiếu đã lưu) ----------
class Calc {
  final double gross; // tổng cân
  final int bags; // số bao đã cân
  final double tarePerBag; // bì mỗi bao (kg)
  final int? tareBags; // số bao bì để trừ, null = bằng số bao đã cân
  final double doPct; // trừ độ (%), chỉ cà nhân
  final double tapPct; // trừ tạp (%), chỉ cà nhân
  final double price; // đơn giá (đ/kg)

  const Calc({
    required this.gross,
    required this.bags,
    required this.tarePerBag,
    required this.tareBags,
    required this.doPct,
    required this.tapPct,
    required this.price,
  });

  int get tareBagCount => tareBags ?? bags;
  double get tareTotal => tarePerBag * tareBagCount;
  double get afterTare => gross - tareTotal;
  double get doKg => afterTare * doPct / 100;
  double get tapKg => afterTare * tapPct / 100;
  double get net => afterTare - doKg - tapKg;
  double get amount => net * price;
}

// ---------- Phiếu cân đã lưu ----------
class Ticket {
  final String id;
  final int kind; // 0 = cà tươi, 1 = cà nhân
  String customer;
  String note;
  final DateTime time;
  final List<double> cells; // nhiều khối, mỗi khối 25 ô, 0 = ô trống
  final double tarePerBag;
  final int? tareBags;
  final double doPct;
  final double tapPct;
  final double price;

  Ticket({
    required this.id,
    required this.kind,
    required this.customer,
    required this.note,
    required this.time,
    required this.cells,
    required this.tarePerBag,
    required this.tareBags,
    required this.doPct,
    required this.tapPct,
    required this.price,
  });

  int get blockCount => (cells.length / Block.size).ceil();

  Calc get calc => Calc(
    gross: cells.fold<double>(0, (a, b) => a + b),
    bags: cells.where((v) => v > 0).length,
    tarePerBag: tarePerBag,
    tareBags: tareBags,
    doPct: doPct,
    tapPct: tapPct,
    price: price,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'customer': customer,
    'note': note,
    'time': time.toIso8601String(),
    'cells': cells,
    'tarePerBag': tarePerBag,
    'tareBags': tareBags,
    'doPct': doPct,
    'tapPct': tapPct,
    'price': price,
  };

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
    id: j['id'] as String,
    kind: (j['kind'] as num?)?.toInt() ?? 0,
    customer: (j['customer'] as String?) ?? '',
    note: (j['note'] as String?) ?? '',
    time: DateTime.parse(j['time'] as String),
    cells: ((j['cells'] as List?) ?? [])
        .map((e) => (e as num).toDouble())
        .toList(),
    tarePerBag: (j['tarePerBag'] as num?)?.toDouble() ?? 0,
    tareBags: (j['tareBags'] as num?)?.toInt(),
    doPct: (j['doPct'] as num?)?.toDouble() ?? 0,
    tapPct: (j['tapPct'] as num?)?.toDouble() ?? 0,
    price: (j['price'] as num?)?.toDouble() ?? 0,
  );

  // Bản sao để sửa mà không ảnh hưởng danh sách gốc
  Ticket copy() => Ticket.fromJson(toJson());
}
