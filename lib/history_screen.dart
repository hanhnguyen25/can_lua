import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'export.dart';
import 'models.dart';
import 'receipt_screen.dart';
import 'storage.dart';
import 'theme.dart';
import 'utils.dart';

// Cộng dồn số liệu cho thống kê
class _Agg {
  int count = 0;
  int bags = 0;
  double net = 0;
  double money = 0;

  void add(Calc c) {
    count++;
    bags += c.bags;
    net += c.net;
    money += c.amount;
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Ticket> tickets = [];
  bool loading = true;

  // Tab Phiếu
  String query = '';
  int kindFilter = -1; // -1 = tất cả

  // Tab Thống kê
  int statKind = 0;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await TicketStore.load();
    if (!mounted) return;
    setState(() {
      tickets = list;
      loading = false;
    });
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  List<Ticket> _inMonth() => tickets
      .where((t) => t.time.year == month.year && t.time.month == month.month)
      .toList();

  Future<void> _onMenu(String v) async {
    try {
      if (v == 'excel_all') {
        if (tickets.isEmpty) {
          _toast('Chưa có phiếu nào');
          return;
        }
        await shareExcel(tickets, label: 'tat_ca');
      } else if (v == 'excel_month') {
        final list = _inMonth();
        if (list.isEmpty) {
          _toast('Tháng ${month.month}/${month.year} chưa có phiếu nào');
          return;
        }
        await shareExcel(
          list,
          label: 'thang_${two(month.month)}_${month.year}',
        );
      } else if (v == 'backup') {
        if (tickets.isEmpty) {
          _toast('Chưa có phiếu nào để sao lưu');
          return;
        }
        await shareBackup(tickets);
      } else if (v == 'restore') {
        final n = await restoreBackup();
        if (n == null) return;
        await _load();
        _toast(
          n == 0
              ? 'Không có phiếu mới (đã có đủ trong máy)'
              : 'Đã khôi phục $n phiếu',
        );
      }
    } catch (e) {
      _toast('Có lỗi: $e');
    }
  }

  Future<void> _open(Ticket t) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(ticket: t.copy(), isDraft: false),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Lịch sử'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: _onMenu,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'excel_all',
                  child: Text('Xuất Excel - tất cả phiếu'),
                ),
                PopupMenuItem(
                  value: 'excel_month',
                  child: Text('Xuất Excel - tháng đang xem'),
                ),
                PopupMenuItem(value: 'backup', child: Text('Sao lưu')),
                PopupMenuItem(value: 'restore', child: Text('Khôi phục')),
              ],
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            tabs: [
              Tab(text: 'PHIẾU'),
              Tab(text: 'THỐNG KÊ'),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (kIsWeb) _webBanner(),
                  Expanded(
                    child: TabBarView(children: [_listTab(), _statsTab()]),
                  ),
                ],
              ),
      ),
    );
  }

  // Nhắc người dùng bản web: dữ liệu chỉ nằm trong trình duyệt này
  Widget _webBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.black87),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Bản web: phiếu chỉ lưu trong trình duyệt này. '
              'Nhớ bấm Sao lưu (JSON) thường xuyên.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tab Phiếu ----------
  Widget _listTab() {
    final q = query.trim().toLowerCase();
    final shown = tickets.where((t) {
      if (kindFilter >= 0 && t.kind != kindFilter) return false;
      if (q.isEmpty) return true;
      return t.customer.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q);
    }).toList();

    const labels = ['Tất cả', 'Cà tươi', 'Cà nhân'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            style: const TextStyle(fontSize: 14, color: kInk),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 20, color: kInk2),
              hintText: 'Tìm theo tên khách, ghi chú',
              hintStyle: TextStyle(fontSize: 13.5, color: kInk2),
              prefixIconConstraints: BoxConstraints(
                minWidth: 42,
                minHeight: 0,
              ),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (int i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(labels[i]),
                    selected: kindFilter == i - 1,
                    onSelected: (_) => setState(() => kindFilter = i - 1),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 42,
                        color: kLine,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tickets.isEmpty
                            ? 'Chưa có phiếu nào được lưu'
                            : 'Không tìm thấy phiếu phù hợp',
                        style: const TextStyle(color: kInk2, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => _ticketCard(shown[i]),
                ),
        ),
      ],
    );
  }

  Widget _ticketCard(Ticket t) {
    final c = t.calc;
    final accent = kindColor(t.kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(t),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kLine),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.customer.trim().isEmpty
                                    ? '(Không tên)'
                                    : t.customer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${kindNames[t.kind]} · ${fmtDateTime(t.time)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: kInk2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Pill('${c.bags} mạ', color: accent),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${fmtKg(c.net)} kg',
                                style: numStyle(15, color: kNavy),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${fmtMoney(c.amount)} đ',
                                style: numStyle(14, color: kOrange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Vạch màu theo phần, cao đúng bằng thẻ
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 4, color: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Tab Thống kê ----------
  void _shiftMonth(int d) =>
      setState(() => month = DateTime(month.year, month.month + d));

  Widget _statsTab() {
    final list = _inMonth().where((t) => t.kind == statKind).toList();
    final accent = kindColor(statKind);

    final total = _Agg();
    final byDay = <int, _Agg>{};
    final byCustomer = <String, _Agg>{};
    for (final t in list) {
      final c = t.calc;
      total.add(c);
      byDay.putIfAbsent(t.time.day, () => _Agg()).add(c);
      final name = t.customer.trim().isEmpty
          ? '(Không tên)'
          : t.customer.trim();
      byCustomer.putIfAbsent(name, () => _Agg()).add(c);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final customers = byCustomer.entries.toList()
      ..sort((a, b) => b.value.money.compareTo(a.value.money));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Cà tươi')),
            ButtonSegment(value: 1, label: Text('Cà nhân')),
          ],
          selected: {statKind},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => statKind = s.first),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(rPill),
            border: Border.all(color: kLine),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shiftMonth(-1),
              ),
              Expanded(
                child: Text(
                  'Tháng ${month.month}/${month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shiftMonth(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 44,
                  color: kLine,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Không có phiếu trong tháng này',
                  style: TextStyle(color: kInk2, fontSize: 14),
                ),
              ],
            ),
          )
        else ...[
          _totalsCard(total, accent),
          const SizedBox(height: 14),
          const SectionLabel('Theo ngày'),
          const SizedBox(height: 8),
          _dayChart(byDay, accent),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final d in days) _statTile(
                  title: '${two(d)}/${two(month.month)}',
                  subtitle: '${byDay[d]!.count} phiếu · ${fmtKg(byDay[d]!.net)} kg',
                  money: byDay[d]!.money,
                  accent: accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionLabel('Theo khách hàng'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final e in customers) _statTile(
                  title: e.key,
                  subtitle:
                      '${e.value.count} phiếu · ${fmtKg(e.value.net)} kg',
                  money: e.value.money,
                  accent: accent,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _totalsCard(_Agg total, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _totalsCell('SỐ PHIẾU', '${total.count}', Colors.white),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              _totalsCell('SỐ MẠ', '${total.bags}', Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              _totalsCell(
                'KHỐI LƯỢNG THỰC',
                '${fmtKg(total.net)} kg',
                Colors.white,
                size: 19,
              ),
              _totalsCell(
                'THÀNH TIỀN',
                '${fmtMoney(total.money)} đ',
                Colors.white,
                size: 19,
                alignEnd: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalsCell(
    String label,
    String value,
    Color color, {
    double size = 16,
    bool alignEnd = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: color.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              value,
              style: numStyle(size, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // Biểu đồ cột thành tiền theo ngày trong tháng
  Widget _dayChart(Map<int, _Agg> byDay, Color accent) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    double max = 0;
    for (final a in byDay.values) {
      if (a.money > max) max = a.money;
    }

    if (max <= 0) {
      return AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined, size: 18, color: kInk2),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Chưa nhập đơn giá nên chưa có thành tiền theo ngày.',
                style: TextStyle(fontSize: 12.5, color: kInk2, height: 1.3),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Cao nhất ${fmtMoney(max)} đ',
                style: const TextStyle(fontSize: 11, color: kInk2),
              ),
              const Spacer(),
              const Text(
                'đ/ngày',
                style: TextStyle(fontSize: 11, color: kInk2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int d = 1; d <= lastDay; d++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: byDay[d] == null
                                ? 0
                                : (byDay[d]!.money / max * 76).clamp(
                                    3.0,
                                    76.0,
                                  ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d % 5 == 0 || d == 1 ? '$d' : '',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: kInk2,
                              fontFeatures: kTabular,
                            ),
                          ),
                        ],
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

  Widget _statTile({
    required String title,
    required String subtitle,
    required double money,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: kInk2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${fmtMoney(money)} đ',
            style: numStyle(13.5, color: kNavy),
          ),
        ],
      ),
    );
  }
}
