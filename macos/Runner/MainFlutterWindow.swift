import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var menuChannel: FlutterMethodChannel?
  private var directoryChannel: FlutterMethodChannel?
  private var directoryAccess: [String: URL] = [:]

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
    directoryChannel = FlutterMethodChannel(name: "para.workspace/directory",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    directoryChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleDirectory(call, result: result)
    }
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
    DispatchQueue.main.async { [weak self] in
      self?.connectFindMenu(NSApplication.shared.mainMenu)
    }
  }


  private func handleDirectory(_ call: FlutterMethodCall, result: FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    do {
      switch call.method {
      case "bookmarkDirectory":
        guard let path = arguments["path"] as? String else {
          throw NSError(domain: "PARA", code: 1, userInfo: [NSLocalizedDescriptionKey: "Kein Ordner ausgewählt."])
        }
        let url = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).standardizedFileURL.path
        if url.path == home || url.path.hasPrefix(home + "/") {
          result(["path": url.path, "bookmark": NSNull()]); return
        }
        let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        result(try resolveDirectory(bookmark))
      case "resolveDirectory":
        guard let value = arguments["bookmark"] as? String, let data = Data(base64Encoded: value) else {
          throw NSError(domain: "PARA", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ordnerfreigabe nicht lesbar."])
        }
        result(try resolveDirectory(data))
      default: result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(code: "workspace-directory", message: "Der Ordnerzugriff konnte nicht hergestellt werden. Bitte den Ordner erneut auswählen.", details: error.localizedDescription))
    }
  }

  private func resolveDirectory(_ data: Data) throws -> [String: Any] {
    var stale = false
    let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale)
    if directoryAccess[url.path] == nil {
      guard url.startAccessingSecurityScopedResource() else {
        throw NSError(domain: "PARA", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ordnerfreigabe nicht verfügbar."])
      }
      directoryAccess[url.path] = url
    }
    let bookmark = stale ? try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil) : data
    return ["path": url.path, "bookmark": bookmark.base64EncodedString()]
  }

  private func connectFindMenu(_ menu: NSMenu?) {
    for item in menu?.items ?? [] {
      if item.keyEquivalent == "," {
        item.title = "Settings…"
        item.target = self
        item.action = #selector(showWorkspaceSettings(_:))
      }
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

  @objc private func showWorkspaceSettings(_ sender: Any?) {
    menuChannel?.invokeMethod("showSettings", arguments: nil)
  }
}
