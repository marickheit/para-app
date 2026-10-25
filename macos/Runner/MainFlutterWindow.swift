import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var menuChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setContentSize(NSSize(width: 1220, height: 800))
    self.minSize = NSSize(width: 600, height: 480)
    self.title = "P.A.R.A."
    self.center()
    menuChannel = FlutterMethodChannel(
      name: "para.workspace/menu",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
    DispatchQueue.main.async { [weak self] in
      self?.connectFindMenu(NSApplication.shared.mainMenu)
    }
  }

  private func connectFindMenu(_ menu: NSMenu?) {
    for item in menu?.items ?? [] {
      if item.action == NSSelectorFromString("performFindPanelAction:") && item.tag == 1 {
        item.target = self
        item.action = #selector(showWorkspaceSearch(_:))
      }
      connectFindMenu(item.submenu)
    }
  }

  @objc private func showWorkspaceSearch(_ sender: Any?) {
    menuChannel?.invokeMethod("showSearch", arguments: nil)
  }
}
