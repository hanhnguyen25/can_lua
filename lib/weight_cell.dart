import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'utils.dart';

/// Ô nhập số cân dùng chung cho màn hình cân và màn hình sửa số cân.
///
/// Ô trống: nền xám nhạt. Có số: nền trắng, viền màu phần. Đang nhập: viền đậm 2px.
/// Viền focus do chính TextField vẽ, không rebuild theo focus, nhờ vậy bàn phím
/// ảo và con trỏ không bị ngắt giữa lúc nhập.
class WeightCell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode node;
  final Color accent;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onEditingComplete;

  const WeightCell({
    super.key,
    required this.controller,
    required this.node,
    required this.accent,
    required this.onChanged,
    required this.onEditingComplete,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = controller.text.trim();
    final filled = parseNumber(text) > 0;

    // Số dài thì thu nhỏ chữ để không tràn ô trên màn hình hẹp
    final size = text.length <= 3
        ? 19.0
        : text.length == 4
        ? 16.0
        : 14.0;

    return Container(
      decoration: BoxDecoration(
        color: filled ? kSurface : kTint,
        borderRadius: BorderRadius.circular(rCell),
        border: Border.all(
          color: filled ? accent.withValues(alpha: 0.45) : kLine,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: node,
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        cursorColor: accent,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: kNavy,
          fontFeatures: kTabular,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 2,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(rCell),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        onChanged: onChanged,
        onEditingComplete: onEditingComplete,
      ),
    );
  }
}
