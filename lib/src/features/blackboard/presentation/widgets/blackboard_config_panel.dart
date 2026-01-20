import 'package:flutter/material.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_controller.dart';
import 'package:va_edu/src/features/blackboard/domain/blackboard_model.dart';
import 'package:va_edu/src/features/blackboard/application/blackboard_mode.dart';

/// 画板高级配置面板
///
/// 复刻 ClassIn 风格：
/// 画笔模式: 工具切换、粗细、线型、图形、颜色。
/// 橡皮模式: 大小调节。
class BlackboardConfigPanel extends StatelessWidget {
  final BlackboardController controller;

  const BlackboardConfigPanel({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.mode == BlackboardMode.eraser) {
      return _buildEraserPanel(context);
    } else if (controller.mode == BlackboardMode.text) {
      return _buildTextPanel(context);
    }
    return _buildPenPanel(context);
  }

  Widget _buildTextPanel(BuildContext context) {
    final style = controller.currentStyle;
    
    return Card(
      elevation: 8,
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "字体大小",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            // 字体大小选择 (下拉框)
            Row(
              children: [
                 const Icon(Icons.format_size, size: 16, color: Colors.white54),
                 const SizedBox(width: 12),
                 Expanded(
                   child: PopupMenuButton<double>(
                       offset: const Offset(0, 32), // 向下偏移，避免遮挡
                       tooltip: '选择字号',
                       color: const Color(0xFF424242),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       constraints: const BoxConstraints(maxHeight: 300), // 限制最大高度
                       itemBuilder: (context) {
                         return [12.0, 14.0, 16.0, 18.0, 24.0, 36.0, 48.0, 64.0, 72.0].map((size) {
                           return PopupMenuItem<double>(
                             value: size,
                             height: 32, // 紧凑高度
                             child: Text(
                               "${size.toInt()} px",
                               style: TextStyle(
                                 color: Colors.white,
                                 fontSize: 13,
                                 fontWeight: style.width == size ? FontWeight.bold : FontWeight.normal,
                               ),
                             ),
                           );
                         }).toList();
                       },
                       onSelected: (val) {
                          controller.setStyle(style.copyWith(width: val));
                       },
                       child: Container(
                         height: 28, 
                         padding: const EdgeInsets.symmetric(horizontal: 8),
                         decoration: BoxDecoration(
                           color: Colors.white12,
                           borderRadius: BorderRadius.circular(6),
                         ),
                         child: Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(
                               "${style.width.toInt()} px",
                               style: const TextStyle(color: Colors.white, fontSize: 13),
                             ),
                             const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                           ],
                         ),
                       ),
                     ),
                 ),
              ],
            ),
            const SizedBox(height: 16),
             
             // 颜色网格
            const Text(
              "文本颜色",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildColorBtn(0xFFFFFFFF, style.color),
                _buildColorBtn(0xFFCFD8DC, style.color),
                _buildColorBtn(0xFF546E7A, style.color),
                _buildColorBtn(0xFF000000, style.color),
                
                _buildColorBtn(0xFFFF1744, style.color),
                _buildColorBtn(0xFFFF9100, style.color),
                _buildColorBtn(0xFFFFEA00, style.color),
                _buildColorBtn(0xFF76FF03, style.color),
                
                _buildColorBtn(0xFF00E5FF, style.color),
                _buildColorBtn(0xFF2979FF, style.color),
                _buildColorBtn(0xFFAA00FF, style.color),
                _buildColorBtn(0xFFFF80AB, style.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEraserPanel(BuildContext context) {
    return Card(
      elevation: 8,
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "橡皮擦大小",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                 const Icon(Icons.circle_outlined, size: 12, color: Colors.white54),
                 Expanded(
                   child: SliderTheme(
                     data: SliderTheme.of(context).copyWith(
                       activeTrackColor: Colors.white,
                       inactiveTrackColor: Colors.white24,
                       thumbColor: Colors.white,
                       overlayColor: Colors.white.withValues(alpha: 0.2),
                       thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                     ),
                     child: Slider(
                       value: controller.eraserSize.clamp(10.0, 100.0),
                       min: 10.0,
                       max: 100.0,
                       onChanged: (val) {
                         controller.setEraserSize(val);
                       },
                     ),
                   ),
                 ),
                 const Icon(Icons.circle_outlined, size: 24, color: Colors.white54),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPenPanel(BuildContext context) {
    final style = controller.currentStyle;
    final strokeType = controller.currentStrokeType;
    
    return Card(
      elevation: 8,
      color: const Color(0xFF333333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 工具切换 (画笔 vs 荧光笔)
            Container(
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildToolTab(
                    icon: Icons.edit,
                    isSelected: !style.isHighlighter,
                    onTap: () {
                      controller.setStyle(style.copyWith(
                        isHighlighter: false,
                        color: style.isHighlighter ? 0xFFFFFFFF : style.color,
                        width: style.isHighlighter ? 2.0 : style.width,
                      ));
                    },
                  ),
                  _buildToolTab(
                    icon: Icons.brush, // 荧光笔图标
                    isSelected: style.isHighlighter,
                    onTap: () {
                      controller.setStyle(style.copyWith(
                        isHighlighter: true,
                        width: 15.0,
                        color: 0xFFFFFF00,
                      ));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 2. 粗细滑块
            Row(
              children: [
                 const Icon(Icons.circle, size: 8, color: Colors.white54),
                 Expanded(
                   child: SliderTheme(
                     data: SliderTheme.of(context).copyWith(
                       activeTrackColor: Colors.white,
                       inactiveTrackColor: Colors.white24,
                       thumbColor: Colors.white,
                       overlayColor: Colors.white.withValues(alpha: 0.2),
                       thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                     ),
                     child: Slider(
                       value: style.width.clamp(1.0, 30.0),
                       min: 1.0,
                       max: 30.0,
                       onChanged: (val) {
                         controller.setStyle(style.copyWith(width: val));
                       },
                     ),
                   ),
                 ),
                 const Icon(Icons.circle, size: 16, color: Colors.white54),
              ],
            ),
            
            // 3. 线条样式 (实线/虚线)
            Container(
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _buildStyleTab(
                    icon: Icons.horizontal_rule,
                    isSelected: !style.isDashed,
                    onTap: () => controller.setStyle(style.copyWith(isDashed: false)),
                  ),
                  _buildStyleTab(
                    icon: Icons.more_horiz,
                    isSelected: style.isDashed,
                    onTap: () => controller.setStyle(style.copyWith(isDashed: true)),
                  ),
                ],
              ),
            ),
            
            // 4. 图形选择
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShapeBtn(Icons.gesture, StrokeType.freehand, strokeType),
                _buildShapeBtn(Icons.horizontal_rule, StrokeType.line, strokeType),
                _buildShapeBtn(Icons.circle_outlined, StrokeType.circle, strokeType),
                _buildShapeBtn(Icons.check_box_outline_blank, StrokeType.rect, strokeType),
              ],
            ),
            const SizedBox(height: 16),
            
            // 5. 颜色网格
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildColorBtn(0xFFFFFFFF, style.color),
                _buildColorBtn(0xFFCFD8DC, style.color),
                _buildColorBtn(0xFF546E7A, style.color),
                _buildColorBtn(0xFF000000, style.color),
                
                _buildColorBtn(0xFFFF1744, style.color),
                _buildColorBtn(0xFFFF9100, style.color),
                _buildColorBtn(0xFFFFEA00, style.color),
                _buildColorBtn(0xFF76FF03, style.color),
                
                _buildColorBtn(0xFF00E5FF, style.color),
                _buildColorBtn(0xFF2979FF, style.color),
                _buildColorBtn(0xFFAA00FF, style.color),
                _buildColorBtn(0xFFFF80AB, style.color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolTab({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
  
  Widget _buildStyleTab({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildShapeBtn(IconData icon, StrokeType type, StrokeType currentType) {
    final isSelected = type == currentType;
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? Colors.cyanAccent : Colors.white54,
      onPressed: () {
        controller.setStrokeType(type);
      },
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? Colors.white12 : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildColorBtn(int colorValue, int currentColorValue) {
    final isSelected = colorValue == currentColorValue;
    return GestureDetector(
      onTap: () {
         final currentStyle = controller.currentStyle;
         controller.setStyle(currentStyle.copyWith(color: colorValue));
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Color(colorValue).withAlpha(255), // 显示不透明预览
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [
             if (isSelected) const BoxShadow(color: Colors.black26, blurRadius: 4)
          ]
        ),
        child: isSelected ? const Center(child: Icon(Icons.check, size: 16, color: Colors.white)) : null,
      ),
    );
  }
}
