import Cocoa
import CryptoKit
import Darwin
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
      case "ingestStat":
        guard let path = arguments["path"] as? String else { throw NSError(domain: "PARA", code: 10) }
        var status = stat()
        guard Darwin.lstat(path, &status) == 0,
          (status.st_mode & S_IFMT) == S_IFREG || (status.st_mode & S_IFMT) == S_IFDIR else {
          throw NSError(domain: "PARA", code: 10)
        }
        result(["identity": Self.ingestIdentity(status), "signature": Self.ingestSignature(status),
          "directory": (status.st_mode & S_IFMT) == S_IFDIR, "size": status.st_size,
          "package": (try? URL(fileURLWithPath: path).resourceValues(forKeys: [.isPackageKey]))?.isPackage ?? false])
      case "ingestMove":
        guard let source = arguments["source"] as? String,
          let destination = arguments["destination"] as? String,
          let identity = arguments["identity"] as? String else { throw NSError(domain: "PARA", code: 10) }
        var status = stat()
        guard Darwin.lstat(source, &status) == 0, Self.ingestIdentity(status) == identity,
          (status.st_mode & S_IFMT) == S_IFREG || (status.st_mode & S_IFMT) == S_IFDIR,
          Darwin.renamex_np(source, destination, UInt32(RENAME_EXCL)) == 0,
          Darwin.lstat(destination, &status) == 0, Self.ingestIdentity(status) == identity else {
          throw NSError(domain: "PARA", code: 10)
        }
        result(nil)
      case "ingestCopy":
        guard let source = arguments["source"] as? String,
          let destination = arguments["destination"] as? String,
          let signature = arguments["signature"] as? String else { throw NSError(domain: "PARA", code: 10) }
        DispatchQueue.global(qos: .utility).async {
          let hash = Self.copyIngest(source, destination, signature)
          DispatchQueue.main.async {
            if let hash = hash { result(hash) }
            else { result(FlutterError(code: "ingest-copy", message: "Datei nicht vollständig übernommen; Original bleibt erhalten.", details: nil)) }
          }
        }
      case "releaseDirectory":
        if let path = arguments["path"] as? String, let url = directoryAccess.removeValue(forKey: path) {
          url.stopAccessingSecurityScopedResource()
        }
        result(nil)
      case "defaultMcpDirectory":
        result(NSHomeDirectory() + "/Library/Application Support/para-mcp")
      case "prepareMcpDirectory", "preparePrivateDirectory":
        guard let path = arguments["path"] as? String else {
          throw NSError(domain: "PARA", code: 4)
        }
        try FileManager.default.createDirectory(atPath: path,
          withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        var status = stat()
        guard Darwin.lstat(path, &status) == 0,
              (status.st_mode & S_IFMT) == S_IFDIR,
              (status.st_mode & 0o777) == 0o700,
              status.st_uid == Darwin.geteuid() else {
          throw NSError(domain: "PARA", code: 5)
        }
        result(nil)
      case "writeMcpConnection":
        guard let path = arguments["path"] as? String,
              let content = arguments["content"] as? String else {
          throw NSError(domain: "PARA", code: 4)
        }
        let target = URL(fileURLWithPath: path)
        var status = stat()
        if Darwin.lstat(path, &status) == 0 {
          guard (status.st_mode & S_IFMT) == S_IFREG,
                (status.st_mode & 0o777) == 0o600,
                status.st_uid == Darwin.geteuid() else {
            throw NSError(domain: "PARA", code: 5)
          }
        } else if errno != ENOENT {
          throw NSError(domain: "PARA", code: 5)
        }
        let temporary = target.deletingLastPathComponent().appendingPathComponent(".para-mcp-\(UUID().uuidString).tmp").path
        let fd = Darwin.open(temporary, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw NSError(domain: "PARA", code: 6) }
        defer { Darwin.close(fd); Darwin.unlink(temporary) }
        let data = Data(content.utf8)
        let written = data.withUnsafeBytes { buffer in
          Darwin.write(fd, buffer.baseAddress, buffer.count)
        }
        guard written == data.count, Darwin.fsync(fd) == 0,
              Darwin.rename(temporary, path) == 0 else {
          throw NSError(domain: "PARA", code: 7)
        }
        result(nil)
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
      let isIngest = call.method.hasPrefix("ingest") || call.method == "preparePrivateDirectory"
      let isMcp = call.method == "prepareMcpDirectory" || call.method == "writeMcpConnection" || call.method == "defaultMcpDirectory"
      result(FlutterError(code: isIngest ? "ingest-file" : (isMcp ? "mcp-connection" : "workspace-directory"),
        message: isIngest ? "Eingangsdatei verändert oder Ordner nicht zugänglich. Originale bleiben erhalten." : (isMcp ? "Sichere lokale MCP-Verbindung konnte nicht eingerichtet werden." : "Der Ordnerzugriff konnte nicht hergestellt werden. Bitte den Ordner erneut auswählen."),
        details: error.localizedDescription))
    }
  }

  private static func ingestIdentity(_ status: stat) -> String {
    "\(status.st_dev):\(status.st_ino)"
  }

  private static func ingestSignature(_ status: stat) -> String {
    "\(ingestIdentity(status))|\(status.st_mtimespec.tv_sec):\(status.st_mtimespec.tv_nsec)|\(status.st_size)|\(status.st_mode & S_IFMT)"
  }

  private static func copyIngest(_ source: String, _ destination: String, _ signature: String) -> String? {
    let input = Darwin.open(source, O_RDONLY | O_NOFOLLOW)
    guard input >= 0 else { return nil }
    defer { Darwin.close(input) }
    var status = stat()
    guard Darwin.fstat(input, &status) == 0, (status.st_mode & S_IFMT) == S_IFREG,
      ingestSignature(status) == signature else { return nil }
    let output = Darwin.open(destination, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
    guard output >= 0 else { return nil }
    defer { Darwin.close(output) }
    let buffer = UnsafeMutableRawPointer.allocate(byteCount: 1024 * 1024, alignment: 16)
    defer { buffer.deallocate() }
    var hasher = SHA256()
    while true {
      let count = Darwin.read(input, buffer, 1024 * 1024)
      if count < 0 && errno == EINTR { continue }
      if count < 0 { return nil }
      if count == 0 { break }
      hasher.update(data: Data(bytes: buffer, count: count))
      var offset = 0
      while offset < count {
        let written = Darwin.write(output, buffer.advanced(by: offset), count - offset)
        if written < 0 && errno == EINTR { continue }
        if written <= 0 { return nil }
        offset += written
      }
    }
    guard Darwin.fstat(input, &status) == 0, ingestSignature(status) == signature, Darwin.fsync(output) == 0 else { return nil }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
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
      if item.keyEquivalent == "w" && item.action == NSSelectorFromString("performClose:") {
        item.target = self
        item.action = #selector(closeWorkspaceDocument(_:))
      }
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

  @objc private func closeWorkspaceDocument(_ sender: Any?) {
    menuChannel?.invokeMethod("closeDocument", arguments: nil) { [weak self] result in
      if (result as? Bool) == true { return }
      self?.performClose(sender)
    }
  }

  @objc private func showWorkspaceSearch(_ sender: Any?) {
    menuChannel?.invokeMethod("showSearch", arguments: nil)
  }

  @objc private func showWorkspaceSettings(_ sender: Any?) {
    menuChannel?.invokeMethod("showSettings", arguments: nil)
  }
}
