import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    // 强化方案：设置内容区域的最小尺寸，这比设置窗口 minSize 更直接有效
    self.contentMinSize = NSSize(width: 800, height: 600)
    
    // 如果当前窗口尺寸小于 800x600，强制放大到 800x600
    var rect = self.frame
    if rect.size.width < 800 || rect.size.height < 600 {
        rect.size.width = max(rect.size.width, 800)
        rect.size.height = max(rect.size.height, 600)
        self.setFrame(rect, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
