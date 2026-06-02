import Cocoa
import FlutterMacOS
import UniformTypeIdentifiers

public class PdfFileAccessPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "pdf_edit/file_access",
      binaryMessenger: registrar.messenger
    )
    let instance = PdfFileAccessPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickPdfFile":
      pickPdfFile(call, result: result)
    case "stagePdfFile":
      stagePdfFile(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickPdfFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = false
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.showsHiddenFiles = false

    if #available(macOS 11.0, *) {
      panel.allowedContentTypes = [UTType.pdf]
    } else {
      panel.allowedFileTypes = ["pdf"]
    }

    if let initialDirectory = args?["initialDirectory"] as? String,
      !initialDirectory.isEmpty
    {
      panel.directoryURL = URL(fileURLWithPath: initialDirectory)
    }

    guard panel.runModal() == .OK, let sourceURL = panel.url else {
      result(nil)
      return
    }

    do {
      let staged = try copyToStaging(sourceURL: sourceURL, fileName: sourceURL.lastPathComponent)
      result(staged)
    } catch {
      result(
        FlutterError(
          code: "stage_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func stagePdfFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let sourcePath = args["sourcePath"] as? String,
      let fileName = args["name"] as? String
    else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "Missing sourcePath or name",
          details: nil
        )
      )
      return
    }

    let bookmarkData = (args["bookmark"] as? FlutterStandardTypedData)?.data

    do {
      let sourceURL = try resolveSourceURL(path: sourcePath, bookmark: bookmarkData)
      let staged = try copyToStaging(sourceURL: sourceURL, fileName: fileName)
      result(staged)
    } catch {
      result(
        FlutterError(
          code: "stage_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func resolveSourceURL(path: String, bookmark: Data?) throws -> URL {
    if let bookmark = bookmark {
      var stale = false

      if let url = try? URL(
        resolvingBookmarkData: bookmark,
        options: [.withSecurityScope],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      ) {
        return url
      }

      if let url = try? URL(
        resolvingBookmarkData: bookmark,
        options: [],
        relativeTo: nil,
        bookmarkDataIsStale: &stale
      ) {
        return url
      }
    }

    return URL(fileURLWithPath: path)
  }

  private func copyToStaging(sourceURL: URL, fileName: String) throws -> [String: Any] {
    let accessing = sourceURL.startAccessingSecurityScopedResource()
    defer {
      if accessing {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }

    let stagingDir = try stagingDirectory()
    let destURL = stagingDir.appendingPathComponent(uniqueFileName(for: fileName))

    if FileManager.default.fileExists(atPath: destURL.path) {
      try FileManager.default.removeItem(at: destURL)
    }

    try FileManager.default.copyItem(at: sourceURL, to: destURL)

    let attributes = try FileManager.default.attributesOfItem(atPath: destURL.path)
    let size = attributes[.size] as? Int64 ?? 0

    return [
      "path": destURL.path,
      "name": fileName,
      "size": Int(size),
      "sourceDirectory": sourceURL.deletingLastPathComponent().path,
    ]
  }

  private func stagingDirectory() throws -> URL {
    let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let dir = base.appendingPathComponent("pdf_staging", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  private func uniqueFileName(for fileName: String) -> String {
    let stamp = Int(Date().timeIntervalSince1970 * 1_000_000)
    return "\(stamp)_\(URL(fileURLWithPath: fileName).lastPathComponent)"
  }
}
