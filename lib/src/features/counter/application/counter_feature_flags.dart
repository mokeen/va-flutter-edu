import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 是否启用“状态管理版计数器”（Riverpod 模板）的全局开关。
///
/// - `false`：使用本地 StatefulWidget 模板（local），计数只在页面内生效
/// - `true`：使用 Riverpod 模板（provider），计数会被 AppShell 等外层共享展示
///
/// 这是一个最适合用 `StateProvider<bool>` 的场景：只有一个简单的可变值。
// StateProvider<T>：一个简单可变值（bool/int/String/enum），直接改 .state
// 例：开关、当前 tab、筛选条件（很适合“是否启用状态管理”）
final counterStateManagementEnabledProvider = StateProvider<bool>((ref) => false);
