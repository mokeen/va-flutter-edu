import 'package:flutter/material.dart';

class BlackboardPageControl extends StatelessWidget {
  const BlackboardPageControl({
    super.key,
    required this.currentPageIndex,
    required this.pageCount,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onHome,
    required this.onJumpToPageRequest,
  });

  final int currentPageIndex;
  final int pageCount;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onHome;
  final VoidCallback onJumpToPageRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            onPressed: currentPageIndex > 0 ? onPrevPage : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '上一页',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${currentPageIndex + 1} / $pageCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            onPressed: currentPageIndex < pageCount - 1 ? onNextPage : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '下一页',
          ),
          const SizedBox(width: 4),
          const SizedBox(
            height: 20,
            child: VerticalDivider(color: Colors.white24, width: 1, thickness: 1),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white, size: 20),
            onPressed: onHome,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '回到首页',
          ),
          IconButton(
            icon: const Icon(Icons.input, color: Colors.white, size: 18),
            onPressed: onJumpToPageRequest,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: '跳转指定页',
          ),
        ],
      ),
    );
  }
}
