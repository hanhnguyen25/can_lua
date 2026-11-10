import 'package:flutter/material.dart';

import 'export.dart';
import 'models.dart';
import 'receipt_screen.dart';
import 'storage.dart';
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
            tabs: [
              Tab(text: 'PHIẾU'),
              Tab(text: 'THỐNG KÊ'),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [_listTab(), _statsTab()]),
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
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm theo tên khách, ghi chú',
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
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
                  child: Text(
                    tickets.isEmpty
                        ? 'Chưa có phiếu nào được lưu'
                        : 'Không tìm thấy phiếu phù hợp',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final t = shown[i];
                    final c = t.calc;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: kindColor(t.kind),
                          child: const Icon(Icons.scale, color: Colors.white),
                        ),
                        title: Text(
                          t.customer.trim().isEmpty
                              ? '(Không tên)'
                              : t.customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${kindNames[t.kind]} · ${fmtDateTime(t.time)} · ${c.bags} bao',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${fmtKg(c.net)} kg',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('${fmtMoney(c.amount)} đ'),
                          ],
                        ),
                        onTap: () => _open(t),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------- Tab Thống kê ----------
  void _shiftMonth(int d) =>
      setState(() => month = DateTime(month.year, month.month + d));

  Widget _statsTab() {
    final list = _inMonth().where((t) => t.kind == statKind).toList();

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
      padding: const EdgeInsets.all(10),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Cà tươi')),
            ButtonSegment(value: 1, label: Text('Cà nhân')),
          ],
          selected: {statKind},
          onSelectionChanged: (s) => setState(() => statKind = s.first),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shiftMonth(-1),
            ),
            Text(
              'Tháng ${month.month}/${month.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Không có phiếu trong tháng này')),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statRow('Số phiếu', '${total.count}'),
                  _statRow('Số bao', '${total.bags}'),
                  _statRow(
                    'Khối lượng thực',
                    '${fmtKg(total.net)} kg',
                    bold: true,
                  ),
                  const Divider(),
                  _statRow(
                    'Thành tiền',
                    '${fmtMoney(total.money)} đ',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          _header('Theo ngày'),
          Card(
            child: Column(
              children: [
                for (final d in days)
                  ListTile(
                    dense: true,
                    title: Text('${two(d)}/${two(month.month)}'),
                    subtitle: Text(
                      '${byDay[d]!.count} phiếu · ${fmtKg(byDay[d]!.net)} kg',
                    ),
                    trailing: Text(
                      '${fmtMoney(byDay[d]!.money)} đ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          _header('Theo khách hàng'),
          Card(
            child: Column(
              children: [
                for (final e in customers)
                  ListTile(
                    dense: true,
                    title: Text(e.key),
                    subtitle: Text(
                      '${e.value.count} phiếu · ${fmtKg(e.value.net)} kg',
                    ),
                    trailing: Text(
                      '${fmtMoney(e.value.money)} đ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _header(String s) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
    child: Text(
      s,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _statRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 18 : 15,
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
