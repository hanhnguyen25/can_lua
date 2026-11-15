import 'package:flutter/material.dart';

import 'utils.dart';

// ---------- Hệ thống giao diện dùng chung ----------
// Một thang bo góc duy nhất: thẻ 18, ô nhập 12, nút và nhãn dạng viên thuốc.
const double rCard = 18;
const double rCell = 12;
const double rPill = 999;

// Số liệu luôn dùng chữ số đều bề rộng để các cột thẳng hàng, dễ so sánh.
const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

TextStyle numStyle(
  double size, {
  Color color = kNavy,
  FontWeight weight = FontWeight.w800,
  double? letterSpacing,
}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: letterSpacing,
  height: 1.05,
  fontFeatures: kTabular,
);

// Nhãn nhỏ phía trên một con số
TextStyle labelStyle({Color color = kInk2, double size = 10.5}) => TextStyle(
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: color,
  letterSpacing: 0.9,
);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kBlue).copyWith(
    primary: kBlue,
    onPrimary: Colors.white,
    secondary: kGreen,
    surface: kSurface,
    onSurface: kInk,
    error: kRed,
    outline: kLine,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: kInk, fontSize: 15),
      bodySmall: TextStyle(color: kInk2, fontSize: 13),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rCard),
        side: const BorderSide(color: kLine),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: kLine,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: kInk2, size: 22),
    // Ô nhập: nền xám rất nhẹ, viền mảnh, khi chọn thì viền đậm 2px
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kTint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: kInk2, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: kInk2,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: const TextStyle(color: kInk2, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rCell),
        borderSide: const BorderSide(color: kLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rCell),
        borderSide: const BorderSide(color: kLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rCell),
        borderSide: const BorderSide(color: kBlue, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kNavy,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: kLine, width: 1.5),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBlue,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSurface,
      selectedColor: kBlue.withValues(alpha: 0.12),
      side: const BorderSide(color: kLine),
      labelStyle: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rCard),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kInk,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCell)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: kSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kLine),
      ),
      textStyle: const TextStyle(fontSize: 15, color: kInk),
    ),
    listTileTheme: const ListTileThemeData(iconColor: kInk2),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBlue),
  );
}

// ---------- Widget nền dùng lại ----------
/// Thẻ trắng viền mảnh, bo góc 18. Không đổ bóng để màn hình không bị nặng.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = kSurface,
    this.borderColor,
    this.radius = rCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? kLine),
      ),
      child: child,
    );
  }
}

/// Tiêu đề nhóm nhỏ, chữ hoa, có đường kẻ mảnh nối phía sau.
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: labelStyle(color: color ?? kInk2, size: 10.5),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1, color: kLine)),
      ],
    );
  }
}

/// Thanh nắm kéo ở đầu các bảng trượt lên.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD6E0),
          borderRadius: BorderRadius.circular(rPill),
        ),
      ),
    );
  }
}

/// Nhãn dạng viên thuốc nhỏ (số mạ, khối, trạng thái).
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;

  const Pill(
    this.text, {
    super.key,
    this.color = kInk2,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : color,
              fontFeatures: kTabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Một chỉ số nhỏ: nhãn ở trên, số ở dưới.
class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color valueColor;
  final IconData? icon;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor = kNavy,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: kInk2),
          const SizedBox(width: 5),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle(size: 10)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: numStyle(14, color: valueColor)),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: kInk2,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
