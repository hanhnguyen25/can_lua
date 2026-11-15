import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'do_am_ca_phe.dart';
import 'export.dart';
import 'grid_editor.dart';
import 'models.dart';
import 'storage.dart';
import 'theme.dart';
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
    final accent = kindColor(t.kind);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Đầu phiếu: màu theo phần, tên phần và thời điểm cân
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PHIẾU CÂN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kindNames[t.kind].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  fmtDateTime(t.time),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (t.customer.trim().isNotEmpty)
            _infoRow(Icons.person_outline, 'Khách hàng', t.customer.trim()),
          if (t.note.trim().isNotEmpty)
            _infoRow(Icons.sticky_note_2_outlined, 'Ghi chú', t.note.trim()),
          const SizedBox(height: 6),
          for (int b = 0; b < t.blockCount; b++) _block(b),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: kTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _row('Số mạ', '${c.bags}'),
                _row('Tổng cân', '${fmtKg(c.gross)} kg'),
                _row('Số bao bì trừ', '${c.tareBagCount}'),
                _row('Trừ bì', '${fmtKg(c.tareTotal)} kg'),
                if (isNhan) ...[
                  if (t.doAm > 0) _row('Độ ẩm', '${fmtNum(t.doAm)} %'),
                  _row('Trừ độ (${fmtPct(c.doPct)}%)', '${fmtKg(c.doKg)} kg'),
                  _row('Trừ tạp (${fmtPct(c.tapPct)}%)', '${fmtKg(c.tapKg)} kg'),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Divider(height: 1, color: kLine),
                ),
                _row('Khối lượng thực', '${fmtKg(c.net)} kg', bold: true),
                if (t.price > 0)
                  _row('Đơn giá', '${fmtMoney(t.price)} đ/kg'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: kOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kOrange.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thành tiền',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${fmtMoney(c.amount)} đ',
                      style: numStyle(22, color: kOrange),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: kInk2),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kInk2,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: kInk,
              ),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              for (int col = 0; col < Block.cols; col++)
                Expanded(
                  child: Center(
                    child: Text(
                      '${b * Block.size + (col + 1) * Block.rows}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: kInk2,
                        fontFeatures: kTabular,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int col = 0; col < Block.cols; col++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Column(
                      children: [
                        for (int r = 0; r < Block.rows; r++)
                          SizedBox(
                            height: 24,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  v(col * Block.rows + r) > 0
                                      ? fmtNum(v(col * Block.rows + r))
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: kNavy,
                                    fontFeatures: kTabular,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (int col = 0; col < Block.cols; col++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        colTotal(col) > 0 ? fmtKg(colTotal(col)) : '',
                        style: numStyle(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1, color: kLine),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng khối ${b + 1}',
                style: const TextStyle(fontSize: 12, color: kInk2),
              ),
              Text(
                '${fmtKg(blockTotal)} kg',
                style: numStyle(14, color: kNavy),
              ),
            ],
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
      fontSize: big ? 20 : (bold ? 15 : 13.5),
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? kInk : kInk2,
      fontFeatures: kTabular,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: style.copyWith(
                color: bold ? kInk : kInk,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
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
    ValueChanged<String> onChanged, {
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: kInk,
        fontFeatures: kTabular,
      ),
      decoration: InputDecoration(
        labelText: nhan,
        isDense: true,
        prefixIcon: icon == null ? null : Icon(icon, size: 18, color: kInk2),
        prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 0),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rCell),
          borderSide: BorderSide(color: kindColor(t.kind), width: 2),
        ),
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
    final accent = kindColor(t.kind);
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: accent,
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionLabel('Người cân'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: customerCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kInk,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Tên khách hàng',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              size: 18,
                              color: kInk2,
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 38,
                              minHeight: 0,
                            ),
                          ),
                          onChanged: (v) =>
                              setState(() => t.customer = v.trim()),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteCtrl,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: kInk,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú',
                            prefixIcon: Icon(
                              Icons.sticky_note_2_outlined,
                              size: 18,
                              color: kInk2,
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 38,
                              minHeight: 0,
                            ),
                          ),
                          onChanged: (v) => setState(() => t.note = v.trim()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionLabel('Thông số phiếu'),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _oSo(
                                'Bì mỗi bao (kg)',
                                tareCtrl,
                                _onTareChanged,
                                icon: Icons.inventory_2_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _oSo(
                                'Số bao bì trừ',
                                bagTareCtrl,
                                _onBagTareChanged,
                                icon: Icons.layers_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Số mạ',
                                  isDense: true,
                                  prefixIcon: Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                    color: kInk2,
                                  ),
                                  prefixIconConstraints: BoxConstraints(
                                    minWidth: 38,
                                    minHeight: 0,
                                  ),
                                ),
                                child: Text(
                                  '${t.calc.bags}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: kTabular,
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
                                icon: Icons.sell_outlined,
                              ),
                            ),
                          ],
                        ),
                        if (t.kind == 1) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _oSo(
                                  'Độ ẩm (%)',
                                  doAmCtrl,
                                  _onDoAmChanged,
                                  icon: Icons.water_drop_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _oSo(
                                  'Trừ tạp (%)',
                                  tapCtrl,
                                  _onTapChanged,
                                  icon: Icons.filter_alt_outlined,
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
                            prefixIcon: Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: kInk2,
                            ),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 38,
                              minHeight: 0,
                            ),
                          ),
                          child: Text(
                            fmtMoney(t.calc.amount),
                            style: numStyle(16, color: kOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel('Phiếu gửi khách'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(rCard),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kLine),
                        borderRadius: BorderRadius.circular(rCard),
                      ),
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: ReceiptView(ticket: t),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: kSurface,
              border: Border(top: BorderSide(color: kLine)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _shareImage,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Chia sẻ ảnh'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          widget.isDraft ? 'Lưu phiếu' : 'Lưu thay đổi',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
