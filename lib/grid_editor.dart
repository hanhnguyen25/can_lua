import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'utils.dart';
import 'weight_cell.dart';

// ---------- Sửa số cân của một phiếu đã lưu ----------
// Dùng lại đúng cách chia lưới 5 cột x 5 hàng như màn hình cân.
// Trả về danh sách ô mới (mỗi khối 25 ô) qua Navigator.pop.
class GridEditorScreen extends StatefulWidget {
  final List<double> cells;
  final Color color;

  const GridEditorScreen({super.key, required this.cells, required this.color});

  @override
  State<GridEditorScreen> createState() => _GridEditorScreenState();
}

class _GridEditorScreenState extends State<GridEditorScreen> {
  final List<Block> blocks = [];

  @override
  void initState() {
    super.initState();
    // Chia số ô đã lưu thành các khối 25 ô; phiếu luôn có ít nhất 1 khối
    final count = (widget.cells.length / Block.size).ceil();
    final blockCount = count < 1 ? 1 : count;
    for (int b = 0; b < blockCount; b++) {
      final block = Block();
      for (int i = 0; i < Block.size; i++) {
        final idx = b * Block.size + i;
        if (idx < widget.cells.length && widget.cells[idx] > 0) {
          block.ctrls[i].text = fmtNum(widget.cells[idx]);
        }
      }
      blocks.add(block);
    }
  }

  int get bagCount => blocks.fold(0, (s, b) => s + b.count);
  double get grossTotal => blocks.fold(0.0, (s, b) => s + b.total);

  void _onChanged() {
    setState(() {
      // Giống màn hình cân: cột cuối đầy thì tự thêm khối mới
      if (blocks.last.lastColFull) blocks.add(Block());
    });
  }

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

  void _removeBlock(int bi) {
    if (blocks.length == 1) return;
    final removed = blocks.removeAt(bi);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _save() {
    // Bỏ các khối rỗng ở cuối, giữ nguyên thứ tự các khối có số
    int end = blocks.length;
    while (end > 1 && blocks[end - 1].count == 0) {
      end--;
    }
    final values = <double>[];
    for (int b = 0; b < end; b++) {
      values.addAll(blocks[b].values);
    }
    Navigator.pop(context, values);
  }

  @override
  void dispose() {
    for (final b in blocks) {
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        title: const Text('Sửa số cân'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, color: Colors.white, size: 20),
              label: const Text(
                'Xong',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: accent.withValues(alpha: 0.07),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sửa trực tiếp vào các ô, ô trống = bao chưa cân.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: kInk,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              children: [
                for (int bi = 0; bi < blocks.length; bi++) _blockCard(bi),
                OutlinedButton.icon(
                  onPressed: _addBlock,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm khối'),
                ),
              ],
            ),
          ),
          _bottomBar(),
        ],
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
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 0),
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
                Pill('${s.count}/25', color: widget.color),
                const Spacer(),
                IconButton(
                  tooltip: 'Xóa khối',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  onPressed: blocks.length > 1 ? () => _removeBlock(bi) : null,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: kRed,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int c = 0; c < Block.cols; c++)
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                        ),
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
                              accent: widget.color,
                              onChanged: (_) => _onChanged(),
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
          Container(
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
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 12, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kLine)),
            ),
            child: Row(
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
                Pill('${s.count} mạ', color: widget.color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kLine)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.scale_outlined, color: kInk2, size: 20),
              const SizedBox(width: 8),
              Text(
                fmtKg(grossTotal),
                style: numStyle(22),
              ),
              const SizedBox(width: 3),
              const Text(
                'kg',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: kInk2,
                ),
              ),
              const Spacer(),
              Pill('$bagCount mạ', color: widget.color),
            ],
          ),
        ),
      ),
    );
  }
}
