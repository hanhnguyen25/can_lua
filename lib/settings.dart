import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// ---------- Cài đặt nhập liệu, nhớ riêng cho từng phần ----------
// Lưu nguyên chuỗi người dùng đã gõ để mở app lại thấy đúng như cũ.
class WeighSettings {
  final String tareText; // bì mỗi bao (kg)
  final String bagTareText; // số bao bì để trừ
  final String doAmText; // độ ẩm (%) — dùng để tra bảng trừ độ
  final String tapText; // trừ tạp (%)
  final String priceText; // đơn giá (đ/kg)
  final String autoNextText; // tự xuống ô sau khi nhập đủ N số (0 = tắt)

  const WeighSettings({
    this.tareText = '',
    this.bagTareText = '',
    this.doAmText = '',
    this.tapText = '',
    this.priceText = '',
    this.autoNextText = '2',
  });

  bool get isEmpty =>
      tareText.isEmpty &&
      bagTareText.isEmpty &&
      doAmText.isEmpty &&
      tapText.isEmpty &&
      priceText.isEmpty;

  Map<String, dynamic> toJson() => {
    'tare': tareText,
    'bagTare': bagTareText,
    'doAm': doAmText,
    'tapPct': tapText,
    'price': priceText,
    'autoNext': autoNextText,
  };

  factory WeighSettings.fromJson(Map<String, dynamic> j) => WeighSettings(
    tareText: (j['tare'] as String?) ?? '',
    bagTareText: (j['bagTare'] as String?) ?? '',
    // Khoá 'doPct' là % trừ độ của bản cũ — khác đơn vị với độ ẩm nên bỏ qua.
    doAmText: (j['doAm'] as String?) ?? '',
    tapText: (j['tapPct'] as String?) ?? '',
    priceText: (j['price'] as String?) ?? '',
    autoNextText: (j['autoNext'] as String?) ?? '2',
  );
}

class SettingsStore {
  static const _key = 'weigh_settings_v1';

  // kind: 0 = Cà tươi, 1 = Cà nhân
  static Future<WeighSettings> load(int kind) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readAll(prefs.getString(_key));
    final part = map['$kind'];
    if (part is Map) {
      return WeighSettings.fromJson(Map<String, dynamic>.from(part));
    }
    return const WeighSettings();
  }

  static Future<void> save(int kind, WeighSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _readAll(prefs.getString(_key));
    map['$kind'] = s.toJson();
    await prefs.setString(_key, jsonEncode(map));
  }

  static Map<String, dynamic> _readAll(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // dữ liệu hỏng thì coi như chưa có gì
    }
    return {};
  }
}
