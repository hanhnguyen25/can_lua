import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class TicketStore {
  static const _key = 'tickets_v1';

  // Đọc tất cả phiếu, mới nhất ở đầu
  static Future<List<Ticket>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  static Future<void> saveAll(List<Ticket> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }

  // Thêm mới, hoặc cập nhật nếu đã có phiếu cùng id
  static Future<void> upsert(Ticket t) async {
    final list = await load();
    final i = list.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      list[i] = t;
    } else {
      list.add(t);
    }
    await saveAll(list);
  }

  static Future<void> delete(String id) async {
    final list = await load();
    list.removeWhere((t) => t.id == id);
    await saveAll(list);
  }

  // Gộp phiếu từ file sao lưu, bỏ phiếu trùng id. Trả về số phiếu thêm mới.
  static Future<int> merge(List<Ticket> incoming) async {
    final list = await load();
    final ids = list.map((t) => t.id).toSet();
    int added = 0;
    for (final t in incoming) {
      if (ids.add(t.id)) {
        list.add(t);
        added++;
      }
    }
    await saveAll(list);
    return added;
  }
}
