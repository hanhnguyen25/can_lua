import 'package:can_lua/models.dart';
import 'package:can_lua/settings.dart';
import 'package:can_lua/storage.dart';
import 'package:can_lua/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Ticket _ticket({
  String id = 'a',
  int kind = 0,
  String customer = '',
  List<double> cells = const [60, 61.5],
  int? tareBags,
  double tarePerBag = 0,
  double doPct = 0,
  double tapPct = 0,
  double price = 0,
  DateTime? time,
}) => Ticket(
  id: id,
  kind: kind,
  customer: customer,
  note: '',
  time: time ?? DateTime(2026, 1, 1, 8, 30),
  cells: [...cells],
  tarePerBag: tarePerBag,
  tareBags: tareBags,
  doPct: doPct,
  tapPct: tapPct,
  price: price,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('đọc số', () {
    test('chấp nhận dấu phẩy và dấu chấm', () {
      expect(parseNumber('62,5'), 62.5);
      expect(parseNumber(' 62.5 '), 62.5);
      expect(parseNumber(''), 0);
      expect(parseNumber('abc'), 0);
    });
  });

  group('định dạng', () {
    test('số cân bỏ số 0 thừa', () {
      expect(fmtNum(60), '60');
      expect(fmtNum(62.5), '62.5');
      expect(fmtNum(62.25), '62.25');
    });

    test('kg lấy 1 chữ số thập phân', () {
      expect(fmtKg(60), '60.0');
      expect(fmtKg(62.5), '62.5');
      expect(fmtKg(0.04), '0.0');
    });

    test('tiền ngăn cách hàng nghìn bằng dấu chấm', () {
      expect(fmtMoney(1234567), '1.234.567');
      expect(fmtMoney(0), '0');
      expect(fmtMoney(999.6), '1.000');
    });

    test('phần trăm bỏ .0 khi là số nguyên', () {
      expect(fmtPct(5), '5');
      expect(fmtPct(5.5), '5.5');
    });
  });

  group('Block (lưới 5x5)', () {
    test('ô thứ i nằm ở cột i ~/ 5 như màn hình hiển thị', () {
      final b = Block();
      b.ctrls[0].text = '60';
      b.ctrls[5].text = '61,5';
      expect(b.colTotal(0), 60);
      expect(b.colTotal(1), 61.5);
      expect(b.total, 121.5);
      expect(b.count, 2);
      b.dispose();
    });

    test('cột cuối đủ 5 ô thì lastColFull = true', () {
      final b = Block();
      expect(b.lastColFull, isFalse);
      for (int r = 0; r < Block.rows; r++) {
        b.ctrls[(Block.cols - 1) * Block.rows + r].text = '50';
      }
      expect(b.lastColFull, isTrue);
      b.dispose();
    });
  });

  group('Calc (công thức tính tiền)', () {
    test('cà tươi: trừ bì theo số bao đã cân', () {
      const c = Calc(
        gross: 122.5,
        bags: 2,
        tarePerBag: 0.2,
        tareBags: null,
        doPct: 0,
        tapPct: 0,
        price: 20000,
      );
      expect(c.tareBagCount, 2);
      expect(c.tareTotal, closeTo(0.4, 1e-9));
      expect(c.afterTare, closeTo(122.1, 1e-9));
      expect(c.doKg, 0);
      expect(c.tapKg, 0);
      expect(c.net, closeTo(122.1, 1e-9));
      expect(c.amount, closeTo(2442000, 1e-6));
    });

    test('cà nhân: trừ độ và tạp tính trên khối lượng sau bì', () {
      const c = Calc(
        gross: 100,
        bags: 2,
        tarePerBag: 0.5,
        tareBags: 2,
        doPct: 10,
        tapPct: 2,
        price: 1000,
      );
      expect(c.afterTare, closeTo(99, 1e-9));
      expect(c.doKg, closeTo(9.9, 1e-9));
      expect(c.tapKg, closeTo(1.98, 1e-9));
      expect(c.net, closeTo(87.12, 1e-9));
      expect(c.amount, closeTo(87120, 1e-6));
    });

    test('số bao bì để trừ khác số bao đã cân', () {
      const c = Calc(
        gross: 100,
        bags: 4,
        tarePerBag: 0.1,
        tareBags: 2,
        doPct: 0,
        tapPct: 0,
        price: 0,
      );
      expect(c.tareBagCount, 2);
      expect(c.tareTotal, closeTo(0.2, 1e-9));
      expect(c.net, closeTo(99.8, 1e-9));
    });
  });

  group('Ticket', () {
    test('JSON giữ đủ dữ liệu, kể cả tareBags = null', () {
      final t = _ticket(kind: 1, customer: 'Chị Lan', doPct: 5);
      final back = Ticket.fromJson(t.toJson());
      expect(back.id, t.id);
      expect(back.kind, 1);
      expect(back.customer, 'Chị Lan');
      expect(back.time, t.time);
      expect(back.cells, t.cells);
      expect(back.tareBags, isNull);
      expect(back.doPct, 5);
      expect(back.blockCount, 1);
      expect(back.calc.gross, 121.5);
      expect(back.calc.bags, 2);
    });

    test('copy sửa được mà không ảnh hưởng bản gốc', () {
      final t = _ticket();
      final c = t.copy()..customer = 'Khác';
      expect(t.customer, '');
      expect(c.customer, 'Khác');
      c.cells[0] = 999;
      expect(t.cells[0], 60);
    });

    test('nhiều khối 25 ô thì blockCount tương ứng', () {
      final t = _ticket(cells: List.filled(60, 50));
      expect(t.blockCount, 3);
      expect(t.calc.bags, 60);
      expect(t.calc.gross, 3000);
    });
  });

  group('SettingsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('mặc định rỗng khi chưa lưu gì', () async {
      final s = await SettingsStore.load(0);
      expect(s.isEmpty, isTrue);
    });

    test('lưu và đọc riêng theo từng phần', () async {
      await SettingsStore.save(
        0,
        const WeighSettings(tareText: '0,2', priceText: '20000'),
      );
      await SettingsStore.save(
        1,
        const WeighSettings(doText: '5', tapText: '2'),
      );

      final tuoi = await SettingsStore.load(0);
      expect(tuoi.tareText, '0,2');
      expect(tuoi.priceText, '20000');
      expect(tuoi.doText, '');

      final nhan = await SettingsStore.load(1);
      expect(nhan.doText, '5');
      expect(nhan.tapText, '2');
      expect(nhan.priceText, '');
    });

    test('dữ liệu hỏng thì trả về mặc định', () async {
      SharedPreferences.setMockInitialValues({
        'weigh_settings_v1': 'không phải json',
      });
      final s = await SettingsStore.load(0);
      expect(s.isEmpty, isTrue);
    });
  });

  group('TicketStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('upsert cập nhật phiếu cùng id thay vì thêm mới', () async {
      await TicketStore.upsert(_ticket(customer: 'A'));
      expect((await TicketStore.load()).length, 1);

      await TicketStore.upsert(_ticket(customer: 'B'));
      final list = await TicketStore.load();
      expect(list.length, 1);
      expect(list.first.customer, 'B');
    });

    test('load trả về phiếu mới nhất ở đầu', () async {
      final old = _ticket(id: 'old', time: DateTime(2026, 1, 1));
      final recent = _ticket(id: 'new', time: DateTime(2026, 2, 1));
      await TicketStore.upsert(old);
      await TicketStore.upsert(recent);
      final list = await TicketStore.load();
      expect(list.first.id, 'new');
    });

    test('merge chỉ thêm phiếu chưa có', () async {
      await TicketStore.upsert(_ticket(id: 'a'));
      final added = await TicketStore.merge([
        _ticket(id: 'a', customer: 'trùng'),
        _ticket(id: 'b', customer: 'mới'),
      ]);
      expect(added, 1);
      final list = await TicketStore.load();
      expect(list.length, 2);
      expect(list.firstWhere((t) => t.id == 'a').customer, '');
    });

    test('delete xóa đúng phiếu', () async {
      await TicketStore.upsert(_ticket(id: 'a'));
      await TicketStore.upsert(_ticket(id: 'b'));
      await TicketStore.delete('a');
      final list = await TicketStore.load();
      expect(list.length, 1);
      expect(list.first.id, 'b');
    });
  });
}
