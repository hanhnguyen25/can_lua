import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'do_am_ca_phe.dart';
import 'history_screen.dart';
import 'models.dart';
import 'receipt_screen.dart';
import 'settings.dart';
import 'theme.dart';
import 'utils.dart';
import 'weight_cell.dart';

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
  final doCtrl = TextEditingController(); // độ ẩm (%), chỉ cà nhân
  final tapCtrl = TextEditingController(); // trừ tạp (%), chỉ cà nhân
  final priceCtrl = TextEditingController();

  Timer? _saveTimer;
  Timer? _autoNextTimer;
  int _autoNextDigits = 2; // 0 = tắt

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
    doAmText: doCtrl.text,
    tapText: tapCtrl.text,
    priceText: priceCtrl.text,
    autoNextText: '$_autoNextDigits',
  );

  // Mở app: điền lại cài đặt của lần dùng trước (chỉ khi ô còn trống)
  Future<void> _restoreSettings() async {
    final s = await SettingsStore.load(widget.id);
    if (!mounted) return;
    setState(() {
      if (tareCtrl.text.isEmpty) tareCtrl.text = s.tareText;
      if (bagTareCtrl.text.isEmpty) bagTareCtrl.text = s.bagTareText;
      if (doCtrl.text.isEmpty) doCtrl.text = s.doAmText;
      if (tapCtrl.text.isEmpty) tapCtrl.text = s.tapText;
      if (priceCtrl.text.isEmpty) priceCtrl.text = s.priceText;
      _autoNextDigits = int.tryParse(s.autoNextText) ?? 2;
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

  // Độ ẩm người dùng nhập (%), chỉ cà nhân mới trừ độ
  double get doAmInput => isNhan ? parseNumber(doCtrl.text) : 0;

  // % trừ độ tra từ bảng theo độ ẩm (0 khi ≤ 15 độ hoặc chưa nhập)
  double get doPercent => isNhan ? phanTramTruTheoDoAm(doAmInput) : 0;

  // Dòng gợi ý dưới ô độ ẩm trong bảng cài đặt
  String get _moTaTruDo {
    if (doCtrl.text.trim().isEmpty) {
      return 'Nhập độ ẩm, app tự tra bảng để trừ độ';
    }
    if (doAmInput > doAmToiDaTraBang) {
      return 'Vượt 25 độ, áp mức trừ tối đa ${fmtPct(phanTramTruToiDa)}%';
    }
    return 'Trừ độ ${fmtPct(doPercent)}% = ${fmtKg(calc.doKg)} kg';
  }

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

  // Tự nhảy sang ô kế tiếp khi đã nhập đủ N số.
  // Chờ 0,4 giây để nếu đang gõ số thập phân (62.5) thì không nhảy sớm.
  void _scheduleAutoNext(int bi, int i) {
    _autoNextTimer?.cancel();
    if (_autoNextDigits < 2) return;
    final text = blocks[bi].ctrls[i].text.trim();
    if (text.length != _autoNextDigits) return;
    if (text.contains('.') || text.contains(',')) return;
    if (parseNumber(text) <= 0) return;
    _autoNextTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (!blocks[bi].nodes[i].hasFocus) return;
      _focusNext(bi, i);
    });
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

  // Phiếu mới: đưa các thông số cài đặt về 0 và lưu luôn trạng thái trống
  void _resetSettings() {
    setState(() {
      tareCtrl.clear();
      bagTareCtrl.clear();
      doCtrl.clear();
      tapCtrl.clear();
      priceCtrl.clear();
    });
    _persistSettings();
  }

  // Bắt đầu phiếu mới: xóa số cân + đưa cài đặt về 0
  void _startNewTicket() {
    _clearGrid();
    _resetSettings();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Làm lại từ đầu?'),
        content: Text(
          'Toàn bộ số cân của phần $partName sẽ bị xóa và các thông số '
          'cài đặt (bì, số bao, độ ẩm, tạp, đơn giá) về 0.',
        ),
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
    if (ok == true) _startNewTicket();
  }

  // ----- Bảng cài đặt -----
  InputDecoration _dec(String label, {String? helper, IconData? icon}) =>
      InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: kInk2),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 38,
          minHeight: 0,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rCell),
          borderSide: BorderSide(color: mainColor, width: 2),
        ),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    required VoidCallback onChanged,
    String? helper,
    IconData? icon,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboard ?? numberKeyboard,
      inputFormatters: formatters,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: kInk,
        fontFeatures: kTabular,
      ),
      decoration: _dec(label, helper: helper, icon: icon),
      onChanged: (_) => onChanged(),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          // Đổi giá trị trong bảng thì cập nhật cả bảng (dòng gợi ý trừ độ)
          // lẫn màn hình cân bên dưới.
          void changed() {
            setSheetState(() {});
            setState(() {});
            _persistSettingsSoon();
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: mainColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(rCell),
                        ),
                        child: Icon(Icons.tune, size: 20, color: mainColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Cài đặt',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: kInk,
                              ),
                            ),
                            Text(
                              partName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: kInk2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pill('Số mạ đã nhập: $bagCount', color: mainColor),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Trọng lượng'),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          tareCtrl,
                          'Bì mỗi bao (kg)',
                          onChanged: changed,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          bagTareCtrl,
                          'Số bao bì để trừ',
                          onChanged: changed,
                          helper: 'Để trống = bằng số bao đã cân',
                          icon: Icons.layers_outlined,
                          keyboard: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isNhan) ...[
                    const SizedBox(height: 18),
                    const SectionLabel('Chất lượng'),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _field(
                            doCtrl,
                            'Độ ẩm (%)',
                            onChanged: changed,
                            helper: _moTaTruDo,
                            icon: Icons.water_drop_outlined,
                            formatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            tapCtrl,
                            'Trừ tạp (%)',
                            onChanged: changed,
                            icon: Icons.filter_alt_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Trừ độ tự tra bảng theo độ ẩm (bảng 15 tới 25 độ).',
                      style: TextStyle(fontSize: 12, color: kInk2),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const SectionLabel('Đơn giá'),
                  const SizedBox(height: 10),
                  _field(
                    priceCtrl,
                    'Đơn giá (đ/kg)',
                    onChanged: changed,
                    icon: Icons.sell_outlined,
                    keyboard: numberKeyboard,
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Cách nhập'),
                  const SizedBox(height: 10),
                  const Text(
                    'Tự xuống ô sau khi nhập đủ:',
                    style: TextStyle(fontSize: 13, color: kInk2),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final lua in const <int, String>{
                        0: 'Tắt',
                        2: '2 số',
                        3: '3 số',
                        4: '4 số',
                      }.entries)
                        ChoiceChip(
                          label: Text(lua.value),
                          selected: _autoNextDigits == lua.key,
                          selectedColor: mainColor.withValues(alpha: 0.12),
                          side: BorderSide(
                            color: _autoNextDigits == lua.key
                                ? mainColor.withValues(alpha: 0.45)
                                : kLine,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _autoNextDigits == lua.key
                                ? darkColor
                                : kInk,
                          ),
                          onSelected: (_) {
                            setSheetState(() => _autoNextDigits = lua.key);
                            setState(() {});
                            _persistSettingsSoon();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: mainColor),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Xong'),
                  ),
                ],
              ),
            ),
          );
        },
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
      doAm: doAmInput,
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
    // Đã lưu phiếu thì xóa lưới + đưa cài đặt về 0 để cân phiếu mới
    if (saved == true) _startNewTicket();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _autoNextTimer?.cancel();
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
          _summaryStrip(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              children: [
                // Luôn giữ một chỗ cố định cho dải gợi ý: nếu để nó biến mất
                // khỏi danh sách thì các ô nhập phía dưới bị tạo lại giữa lúc gõ.
                _hintSlot(),
                for (int bi = 0; bi < blocks.length; bi++) _blockCard(bi),
              ],
            ),
          ),
          _resultBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: mainColor,
      foregroundColor: Colors.white,
      titleSpacing: 14,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.coffee_outlined, size: 19, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CÂN CÀ PHÊ',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  partName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Lịch sử và thống kê',
          icon: const Icon(Icons.history, size: 22),
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
              const Icon(Icons.layers_outlined, size: 23),
              Text(
                '${blocks.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Tùy chọn',
          icon: const Icon(Icons.more_vert, size: 22),
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
        preferredSize: const Size.fromHeight(50),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(rPill),
            ),
            child: Row(
              children: [_tabButton('CÀ TƯƠI', 0), _tabButton('CÀ NHÂN', 1)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, int i) {
    final selected = widget.currentTab == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTab(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(rPill),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: selected ? darkColor : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }

  // Dải tổng hợp: số mạ, tổng cân, trừ bì + thanh tỷ lệ thực/trừ
  Widget _summaryStrip() {
    final c = calc;
    final ratio = c.gross <= 0
        ? 0.0
        : (c.net.clamp(0.0, c.gross) / c.gross).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              MiniStat(
                icon: Icons.shopping_bag_outlined,
                label: 'MẠ',
                value: '${c.bags}',
              ),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: kLine,
              ),
              MiniStat(
                icon: Icons.scale_outlined,
                label: 'TỔNG CÂN',
                value: fmtNum(c.gross),
                unit: 'kg',
              ),
              const Spacer(),
              if (c.tareTotal > 0)
                Pill(
                  'Bì ${fmtNum(c.tareTotal)} kg',
                  color: mainColor,
                  filled: false,
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(rPill),
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                children: [
                  Container(height: 4, color: kLine),
                  Container(
                    height: 4,
                    width: box.maxWidth * ratio,
                    color: mainColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintSlot() {
    // Chỉ nhắc khi đang thấy lưới nhập và chưa có số nào
    final show = bagCount == 0 && blocks.any((b) => !b.collapsed);
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.topCenter,
      child: show
          ? _emptyHint()
          : const SizedBox(width: double.infinity, height: 0),
    );
  }

  Widget _emptyHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        color: mainColor.withValues(alpha: 0.06),
        borderColor: mainColor.withValues(alpha: 0.18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(Icons.touch_app_outlined, size: 18, color: mainColor),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Nhập số cân từng bao. Cân xong bấm TÍNH TIỀN để xem phiếu.',
                style: TextStyle(fontSize: 12.5, color: kInk, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockCard(int bi) {
    final s = blocks[bi];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(rCard),
        border: Border.all(color: kLine),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 0),
            child: Row(
              children: [
                Text(
                  'Khối ${bi + 1}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
                const SizedBox(width: 8),
                Pill('${s.count}/25', color: mainColor),
                const Spacer(),
                IconButton(
                  tooltip: s.collapsed ? 'Mở rộng' : 'Thu gọn',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  icon: Icon(
                    s.collapsed ? Icons.expand_more : Icons.expand_less,
                    size: 22,
                    color: kInk2,
                  ),
                  onPressed: () => setState(() => s.collapsed = !s.collapsed),
                ),
              ],
            ),
          ),
          if (!s.collapsed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(rPill),
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      Container(height: 3, color: kTint),
                      Container(
                        height: 3,
                        width: box.maxWidth * (s.count / Block.size),
                        color: mainColor.withValues(alpha: 0.65),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int c = 0; c < Block.cols; c++)
                    Expanded(
                      child: Column(
                        children: [
                          _columnHead(bi, c),
                          for (int r = 0; r < Block.rows; r++)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 6,
                                left: 3,
                                right: 3,
                              ),
                              child: WeightCell(
                                controller: s.ctrls[c * Block.rows + r],
                                node: s.nodes[c * Block.rows + r],
                                accent: mainColor,
                                autofocus:
                                    widget.id == 0 && bi == 0 && c == 0 && r == 0,
                                onChanged: (_) {
                                  _onChanged();
                                  _scheduleAutoNext(bi, c * Block.rows + r);
                                },
                                onEditingComplete: () =>
                                    _focusNext(bi, c * Block.rows + r),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _columnTotals(s),
          ],
          _blockFooter(s),
        ],
      ),
    );
  }

  // Nhãn tích luỹ số bao của cột: 5, 10, 15, 20, 25
  Widget _columnHead(int bi, int c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: kTint,
          borderRadius: BorderRadius.circular(rPill),
        ),
        child: Text(
          '${bi * Block.size + (c + 1) * Block.rows}',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: kInk2,
            fontFeatures: kTabular,
          ),
        ),
      ),
    );
  }

  Widget _columnTotals(Block s) {
    // Khối chưa nhập gì thì không hiện hàng tổng cột (tránh một dãy số 0 thừa)
    if (s.count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 0),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: Row(
        children: [
          for (int c = 0; c < Block.cols; c++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    s.colTotal(c) > 0 ? fmtKg(s.colTotal(c)) : '',
                    maxLines: 1,
                    style: numStyle(16, color: kNavy),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _blockFooter(Block s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Tổng khối',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kInk2,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(fmtKg(s.total), style: numStyle(21)),
                  const SizedBox(width: 3),
                  const Text(
                    'kg',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: kInk2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Pill('${s.count} mạ', color: mainColor),
        ],
      ),
    );
  }

  // Thanh kết quả luôn hiện: khối lượng thực, thành tiền và nút tính tiền
  Widget _resultBar() {
    final c = calc;
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _resultValue(
                  label: 'KHỐI LƯỢNG THỰC',
                  value: fmtKg(c.net),
                  unit: 'kg',
                  color: kNavy,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: kLine,
              ),
              Expanded(
                flex: 6,
                child: _resultValue(
                  label: 'THÀNH TIỀN',
                  value: fmtMoney(c.amount),
                  unit: 'đ',
                  color: kOrange,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: darkColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: _calculate,
                  child: const Text('TÍNH TIỀN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultValue({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: labelStyle(size: 9.5), maxLines: 1),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: numStyle(23, color: color)),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: kInk2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

