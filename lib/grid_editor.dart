import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'utils.dart';

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

  static const _numberKeyboard = TextInputType.numberWithOptions(decimal: true);

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
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        title: const Text('Sửa số cân'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Xong', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: kPink,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: const Text(
              'Sửa trực tiếp vào các ô, ô trống = bao chưa cân.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                for (int bi = 0; bi < blocks.length; bi++) _blockCard(bi),
                OutlinedButton.icon(
                  onPressed: _addBlock,
                  icon: const Icon(Icons.add),
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
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          children: [
            // Số bao tích luỹ của từng cột
            Row(
              children: [
                for (int c = 0; c < Block.cols; c++)
                  Expanded(
                    child: Center(
                      child: Text(
                        '${bi * Block.size + (c + 1) * Block.rows}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
            const SizedBox(height: 6),
            Row(
              children: [
                for (int c = 0; c < Block.cols; c++)
                  Expanded(
                    child: Text(
                      fmtKg(s.colTotal(c)),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kNavy,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Xóa khối',
                  onPressed: blocks.length > 1 ? () => _removeBlock(bi) : null,
                  icon: const Icon(Icons.delete_outline, color: kRed),
                ),
                Expanded(
                  child: Text(
                    '${fmtKg(s.total)} kg · ${s.count} bao',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
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
        keyboardType: _numberKeyboard,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: kNavy,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
    return Material(
      color: const Color(0xFFF4F8FD),
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.scale, color: kOrange, size: 30),
              const SizedBox(width: 8),
              Text(
                '${fmtKg(grossTotal)} kg',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kNavy,
                ),
              ),
              const Spacer(),
              Text(
                '$bagCount bao',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
