import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'do_am_ca_phe.dart';
import 'export.dart';
import 'grid_editor.dart';
import 'models.dart';
import 'storage.dart';
import 'utils.dart';

// ---------- Phiếu cân dạng hình (cũng là phần được chụp thành ảnh) ----------
class ReceiptView extends StatelessWidget {
  final Ticket ticket;
  const ReceiptView({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    final c = t.calc;
    final isNhan = t.kind == 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'PHIẾU CÂN ${kindNames[t.kind].toUpperCase()}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kindDark(t.kind),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (t.customer.trim().isNotEmpty)
            Text(
              'Khách hàng: ${t.customer.trim()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          Text(
            'Ngày: ${fmtDateTime(t.time)}',
            style: const TextStyle(fontSize: 15),
          ),
          if (t.note.trim().isNotEmpty)
            Text(
              'Ghi chú: ${t.note.trim()}',
              style: const TextStyle(fontSize: 15),
            ),
          const Divider(height: 20),
          for (int b = 0; b < t.blockCount; b++) _block(b),
          const Divider(height: 12),
          _row('Số mạ', '${c.bags}'),
          _row('Tổng cân', '${fmtKg(c.gross)} kg'),
          _row('Số bao bì trừ', '${c.tareBagCount}'),
          _row('Trừ bì', '${fmtKg(c.tareTotal)} kg'),
          if (isNhan) ...[
            if (t.doAm > 0) _row('Độ ẩm', '${fmtNum(t.doAm)} %'),
            _row('Trừ độ (${fmtPct(c.doPct)}%)', '${fmtKg(c.doKg)} kg'),
            _row('Trừ tạp (${fmtPct(c.tapPct)}%)', '${fmtKg(c.tapKg)} kg'),
          ],
          _row('Khối lượng thực', '${fmtKg(c.net)} kg', bold: true),
          if (t.price > 0) _row('Đơn giá', '${fmtMoney(t.price)} đ/kg'),
          const Divider(height: 12),
          _row('Thành tiền', '${fmtMoney(c.amount)} đ', bold: true, big: true),
        ],
      ),
    );
  }

  Widget _block(int b) {
    final base = b * Block.size;
    double v(int i) =>
        base + i < ticket.cells.length ? ticket.cells[base + i] : 0;

    double colTotal(int col) {
      double s = 0;
      for (int r = 0; r < Block.rows; r++) {
        s += v(col * Block.rows + r);
      }
      return s;
    }

    double blockTotal = 0;
    for (int i = 0; i < Block.size; i++) {
      blockTotal += v(i);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              for (int col = 0; col < Block.cols; col++)
                Expanded(
                  child: Center(
                    child: Text(
                      '${b * Block.size + (col + 1) * Block.rows}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int col = 0; col < Block.cols; col++)
                Expanded(
                  child: Column(
                    children: [
                      for (int r = 0; r < Block.rows; r++)
                        SizedBox(
                          height: 26,
                          child: Center(
                            child: Text(
                              v(col * Block.rows + r) > 0
                                  ? fmtNum(v(col * Block.rows + r))
                                  : '',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: kNavy,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 8),
          Row(
            children: [
              for (int col = 0; col < Block.cols; col++)
                Expanded(
                  child: Center(
                    child: Text(
                      fmtKg(colTotal(col)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Tổng khối ${b + 1}: ${fmtKg(blockTotal)} kg',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: kPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    bool big = false,
  }) {
    final style = TextStyle(
      fontSize: big ? 20 : (bold ? 18 : 15),
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ---------- Màn hình xem và lưu phiếu ----------
// isDraft = true: phiếu mới vừa bấm TÍNH TIỀN, chưa lưu
// isDraft = false: phiếu đã lưu, mở từ lịch sử
// Trả về true (qua Navigator.pop) khi đã lưu hoặc xóa
class ReceiptScreen extends StatefulWidget {
  final Ticket ticket;
  final bool isDraft;
  const ReceiptScreen({super.key, required this.ticket, required this.isDraft});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _boundaryKey = GlobalKey();
  late final TextEditingController customerCtrl;
  late final TextEditingController noteCtrl;
  late final TextEditingController tareCtrl;
  late final TextEditingController bagTareCtrl;
  late final TextEditingController doAmCtrl;
  late final TextEditingController tapCtrl;
  late final TextEditingController priceCtrl;
  bool busy = false;

  Ticket get t => widget.ticket;

  @override
  void initState() {
    super.initState();
    customerCtrl = TextEditingController(text: t.customer);
    noteCtrl = TextEditingController(text: t.note);
    tareCtrl = TextEditingController(
      text: t.tarePerBag == 0 ? '' : fmtNum(t.tarePerBag),
    );
    bagTareCtrl = TextEditingController(text: t.tareBags?.toString() ?? '');
    doAmCtrl = TextEditingController(text: t.doAm == 0 ? '' : fmtNum(t.doAm));
    tapCtrl = TextEditingController(
      text: t.tapPct == 0 ? '' : fmtNum(t.tapPct),
    );
    priceCtrl = TextEditingController(
      text: t.price == 0 ? '' : t.price.round().toString(),
    );
  }

  @override
  void dispose() {
    customerCtrl.dispose();
    noteCtrl.dispose();
    tareCtrl.dispose();
    bagTareCtrl.dispose();
    doAmCtrl.dispose();
    tapCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  // Sửa thông số nào cũng tính lại tiền theo công thức
  void _tinhLaiTien() {
    t.amountOverride = null;
  }

  void _onTareChanged(String v) {
    setState(() {
      t.tarePerBag = parseNumber(v);
      _tinhLaiTien();
    });
  }

  void _onBagTareChanged(String v) {
    setState(() {
      final s = v.trim();
      t.tareBags = s.isEmpty ? null : parseNumber(s).round();
      _tinhLaiTien();
    });
  }

  void _onDoAmChanged(String v) {
    setState(() {
      t.doAm = parseNumber(v);
      t.doPct = phanTramTruTheoDoAm(t.doAm);
      _tinhLaiTien();
    });
  }

  void _onTapChanged(String v) {
    setState(() {
      t.tapPct = parseNumber(v);
      _tinhLaiTien();
    });
  }

  void _onPriceChanged(String v) {
    setState(() {
      t.price = parseNumber(v);
      _tinhLaiTien();
    });
  }

  Widget _oSo(
    String nhan,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: nhan,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    t.customer = customerCtrl.text.trim();
    t.note = noteCtrl.text.trim();
    await TicketStore.upsert(t);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _shareImage() async {
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      await shareWidgetImage(_boundaryKey, 'phieu_can_${stamp(t.time)}');
    } catch (e) {
      if (mounted) _toast('Không chia sẻ được: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  // Sửa số cân của phiếu (dùng được cho cả phiếu nháp lẫn phiếu đã lưu)
  Future<void> _editCells() async {
    final values = await Navigator.push<List<double>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GridEditorScreen(cells: t.cells, color: kindColor(t.kind)),
      ),
    );
    if (values == null || !mounted) return;
    setState(() {
      t.cells
        ..clear()
        ..addAll(values);
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiếu này?'),
        content: const Text('Phiếu đã xóa không khôi phục được.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await TicketStore.delete(t.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kindColor(t.kind),
        foregroundColor: Colors.white,
        title: Text(widget.isDraft ? 'Phiếu mới' : 'Chi tiết phiếu'),
        actions: [
          IconButton(
            tooltip: 'Sửa số cân',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editCells,
          ),
          if (!widget.isDraft)
            IconButton(
              tooltip: 'Xóa phiếu',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: customerCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Tên khách hàng',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => t.customer = v.trim()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => t.note = v.trim()),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông số phiếu (sửa được)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _oSo(
                                  'Bì mỗi bao (kg)',
                                  tareCtrl,
                                  _onTareChanged,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _oSo(
                                  'Số bao bì trừ',
                                  bagTareCtrl,
                                  _onBagTareChanged,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Số mạ',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    '${t.calc.bags}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _oSo(
                                  'Đơn giá (đ/kg)',
                                  priceCtrl,
                                  _onPriceChanged,
                                ),
                              ),
                            ],
                          ),
                          if (t.kind == 1) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _oSo(
                                    'Độ ẩm (%)',
                                    doAmCtrl,
                                    _onDoAmChanged,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _oSo(
                                    'Trừ tạp (%)',
                                    tapCtrl,
                                    _onTapChanged,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          // Thành tiền chỉ hiển thị, tính tự động
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Thành tiền (đ)',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              fmtMoney(t.calc.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RepaintBoundary(
                    key: _boundaryKey,
                    child: ReceiptView(ticket: t),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _shareImage,
                      icon: const Icon(Icons.share),
                      label: const Text('Chia sẻ ảnh'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.isDraft ? 'Lưu phiếu' : 'Lưu thay đổi',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
