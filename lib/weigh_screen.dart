import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'history_screen.dart';
import 'models.dart';
import 'receipt_screen.dart';
import 'settings.dart';
import 'utils.dart';

class WeighScreen extends StatefulWidget {
  final int id; // 0 = Cà tươi, 1 = Cà nhân
  final int currentTab;
  final ValueChanged<int> onTab;

  const WeighScreen({
    super.key,
    required this.id,
    required this.currentTab,
    required this.onTab,
  });

  @override
  State<WeighScreen> createState() => _WeighScreenState();
}

class _WeighScreenState extends State<WeighScreen> {
  final List<Block> blocks = [Block()];
  final tareCtrl = TextEditingController(); // bì mỗi bao
  final bagTareCtrl = TextEditingController(); // số bao bì để trừ
  final doCtrl = TextEditingController(); // trừ độ (%), chỉ cà nhân
  final tapCtrl = TextEditingController(); // trừ tạp (%), chỉ cà nhân
  final priceCtrl = TextEditingController();

  Timer? _saveTimer;

  static const numberKeyboard = TextInputType.numberWithOptions(decimal: true);

  bool get isNhan => widget.id == 1;
  String get partName => kindNames[widget.id];
  Color get mainColor => kindColor(widget.id);
  Color get darkColor => kindDark(widget.id);

  @override
  void initState() {
    super.initState();
    _restoreSettings();
  }

  // ----- Nhớ cài đặt (bì, đơn giá, % trừ) riêng cho từng phần -----
  WeighSettings get _settings => WeighSettings(
    tareText: tareCtrl.text,
    bagTareText: bagTareCtrl.text,
    doText: doCtrl.text,
    tapText: tapCtrl.text,
    priceText: priceCtrl.text,
  );

  // Mở app: điền lại cài đặt của lần dùng trước (chỉ khi ô còn trống)
  Future<void> _restoreSettings() async {
    final s = await SettingsStore.load(widget.id);
    if (!mounted) return;
    setState(() {
      if (tareCtrl.text.isEmpty) tareCtrl.text = s.tareText;
      if (bagTareCtrl.text.isEmpty) bagTareCtrl.text = s.bagTareText;
      if (doCtrl.text.isEmpty) doCtrl.text = s.doText;
      if (tapCtrl.text.isEmpty) tapCtrl.text = s.tapText;
      if (priceCtrl.text.isEmpty) priceCtrl.text = s.priceText;
    });
  }

  // Gõ tới đâu lưu tới đó, nhưng gộp lại để không ghi liên tục
  void _persistSettingsSoon() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _persistSettings);
  }

  void _persistSettings() {
    SettingsStore.save(widget.id, _settings);
  }

  // ----- Số liệu tổng hợp -----
  int get bagCount => blocks.fold(0, (s, b) => s + b.count);
  double get grossTotal => blocks.fold(0.0, (s, b) => s + b.total);

  double get doPercent => isNhan ? parseNumber(doCtrl.text) : 0;
  double get tapPercent => isNhan ? parseNumber(tapCtrl.text) : 0;
  int? get tareBagsInput => bagTareCtrl.text.trim().isEmpty
      ? null
      : parseNumber(bagTareCtrl.text).round();

  Calc get calc => Calc(
    gross: grossTotal,
    bags: bagCount,
    tarePerBag: parseNumber(tareCtrl.text),
    tareBags: tareBagsInput,
    doPct: doPercent,
    tapPct: tapPercent,
    price: parseNumber(priceCtrl.text),
  );

  // ----- Xử lý sự kiện -----
  void _onChanged() {
    setState(() {
      // Cột cuối cùng của khối cuối đã đủ 5 ô thì tự thêm khối 5 cột mới
      if (blocks.last.lastColFull) blocks.add(Block());
    });
  }

  // Nhấn "Next" trên bàn phím: nhảy xuống ô kế tiếp (hết cột thì sang cột sau)
  void _focusNext(int bi, int i) {
    FocusNode? next;
    if (i + 1 < Block.size) {
      next = blocks[bi].nodes[i + 1];
    } else if (bi + 1 < blocks.length) {
      next = blocks[bi + 1].nodes[0];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => next?.requestFocus());
  }

  void _addBlock() => setState(() => blocks.add(Block()));

  // Xóa lưới số cân, giữ nguyên bì, đơn giá, % trừ
  void _clearGrid() {
    final old = List<Block>.of(blocks);
    setState(() {
      blocks
        ..clear()
        ..add(Block());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final b in old) {
        b.dispose();
      }
    });
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Làm lại từ đầu?'),
        content: Text('Toàn bộ số cân của phần $partName sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa hết'),
          ),
        ],
      ),
    );
    if (ok == true) _clearGrid();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt - $partName',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tareCtrl,
              keyboardType: numberKeyboard,
              decoration: const InputDecoration(
                labelText: 'Bì mỗi bao (kg)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
                _persistSettingsSoon();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bagTareCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Số bao bì để trừ',
                helperText: 'Để trống = bằng số bao đã cân',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
                _persistSettingsSoon();
              },
            ),
            if (isNhan) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: doCtrl,
                      keyboardType: numberKeyboard,
                      decoration: const InputDecoration(
                        labelText: 'Trừ độ (%)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _persistSettingsSoon();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: tapCtrl,
                      keyboardType: numberKeyboard,
                      decoration: const InputDecoration(
                        labelText: 'Trừ tạp (%)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _persistSettingsSoon();
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: numberKeyboard,
              decoration: const InputDecoration(
                labelText: 'Đơn giá (đ/kg)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
                _persistSettingsSoon();
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Xong'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tạo phiếu nháp từ số liệu đang nhập
  Ticket _buildTicket() {
    final used = blocks.where((b) => b.count > 0);
    final now = DateTime.now();
    return Ticket(
      id: now.microsecondsSinceEpoch.toString(),
      kind: widget.id,
      customer: '',
      note: '',
      time: now,
      cells: [for (final b in used) ...b.values],
      tarePerBag: parseNumber(tareCtrl.text),
      tareBags: tareBagsInput,
      doPct: doPercent,
      tapPct: tapPercent,
      price: parseNumber(priceCtrl.text),
    );
  }

  // TÍNH TIỀN: mở phiếu để xem, nhập tên khách, lưu hoặc chia sẻ
  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();
    if (bagCount == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chưa có số cân nào')));
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(ticket: _buildTicket(), isDraft: true),
      ),
    );
    // Đã lưu phiếu thì xóa lưới để cân phiếu mới
    if (saved == true) _clearGrid();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _persistSettings(); // lưu cài đặt lần cuối trước khi bỏ các controller
    for (final b in blocks) {
      b.dispose();
    }
    tareCtrl.dispose();
    bagTareCtrl.dispose();
    doCtrl.dispose();
    tapCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

  // ----- Giao diện -----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _appBar(),
      body: Column(
        children: [
          _noteBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                for (int bi = 0; bi < blocks.length; bi++) _blockCard(bi),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: mainColor,
      foregroundColor: Colors.white,
      titleSpacing: 12,
      title: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _calculate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: darkColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calculate_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'TÍNH TIỀN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Lịch sử và thống kê',
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
        IconButton(
          tooltip: 'Thêm khối mới',
          onPressed: _addBlock,
          icon: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.layers_outlined, size: 30),
              Text(
                '${blocks.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'settings') _openSettings();
            if (v == 'reset') _confirmReset();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'settings', child: Text('Cài đặt')),
            PopupMenuItem(value: 'reset', child: Text('Xóa số cân')),
          ],
        ),
      ],
      // Hai tab chuyển giữa Cà tươi và Cà nhân
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Row(
          children: [_tabButton('CÀ TƯƠI', 0), _tabButton('CÀ NHÂN', 1)],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int i) {
    final selected = widget.currentTab == i;
    return Expanded(
      child: InkWell(
        onTap: () => widget.onTab(i),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteBanner() {
    return Container(
      width: double.infinity,
      color: kPink,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: const Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '*Lưu ý:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: ' Sau khi nhập xong, nhấn vào TÍNH TIỀN để xem phiếu, lưu hoặc chia sẻ! Nhấn vào ',
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.keyboard_double_arrow_up, size: 20),
            ),
            TextSpan(text: ' để cập nhật các thông tin cài đặt.'),
          ],
        ),
      ),
    );
  }

  Widget _blockCard(int bi) {
    final s = blocks[bi];
    const totalStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: kNavy,
    );

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          children: [
            if (!s.collapsed) ...[
              // Hàng nhãn 5, 10, 15, 20, 25 (số bao tích lũy)
              Row(
                children: [
                  for (int c = 0; c < Block.cols; c++)
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kNavy,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${bi * Block.size + (c + 1) * Block.rows}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Lưới 5 cột, mỗi cột 5 ô xếp dọc
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int c = 0; c < Block.cols; c++)
                    Expanded(
                      child: Column(
                        children: [
                          for (int r = 0; r < Block.rows; r++)
                            _cell(bi, c * Block.rows + r),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Tổng từng cột
            Row(
              children: [
                for (int c = 0; c < Block.cols; c++)
                  Expanded(
                    child: Text(
                      fmtKg(s.colTotal(c)),
                      textAlign: TextAlign.center,
                      style: totalStyle,
                    ),
                  ),
              ],
            ),
            // Hàng cuối: thu gọn | tổng khối | số bao
            Row(
              children: [
                IconButton(
                  tooltip: s.collapsed ? 'Mở rộng' : 'Thu gọn',
                  icon: Icon(
                    s.collapsed
                        ? Icons.keyboard_double_arrow_down
                        : Icons.keyboard_double_arrow_up,
                    color: kOrange,
                    size: 30,
                  ),
                  onPressed: () => setState(() => s.collapsed = !s.collapsed),
                ),
                Expanded(
                  child: Text(
                    fmtKg(s.total),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: kPurple,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  color: kRed,
                  child: Text(
                    '${s.count}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(int bi, int i) {
    final s = blocks[bi];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: s.ctrls[i],
        focusNode: s.nodes[i],
        // Chỉ phần Cà tươi tự đặt con trỏ khi mở app
        autofocus: widget.id == 0 && bi == 0 && i == 0,
        keyboardType: numberKeyboard,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: kNavy,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFDDDDDD), width: 2),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: kNavy, width: 2),
          ),
        ),
        onChanged: (_) => _onChanged(),
        onEditingComplete: () => _focusNext(bi, i),
      ),
    );
  }

  Widget _bottomBar() {
    final c = calc;
    const valueStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: kOrange,
    );
    return Material(
      color: const Color(0xFFF4F8FD),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.grass, color: kOrange, size: 34),
              const SizedBox(width: 8),
              Text(fmtKg(c.net), style: valueStyle),
              Expanded(
                child: Center(
                  child: IconButton(
                    tooltip: 'Cài đặt',
                    icon: const Icon(
                      Icons.keyboard_double_arrow_up,
                      color: kNavy,
                      size: 34,
                    ),
                    onPressed: _openSettings,
                  ),
                ),
              ),
              Text(fmtMoney(c.amount), style: valueStyle),
              const SizedBox(width: 6),
              const Icon(
                Icons.monetization_on_outlined,
                color: kOrange,
                size: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
