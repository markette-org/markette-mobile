import UIKit
import UniformTypeIdentifiers

/// "Share with Markette": collects the shared links, text, images and videos, hands them to the
/// app through the App Group (read by @capgo/capacitor-share-target), then opens Markette.
final class ShareViewController: UIViewController {
    private let appGroupId = "group.app.markette.mobile"
    private let appURL = URL(string: "markette://share")!
    private let maxFileBytes = 200 * 1024 * 1024

    private var texts: [String] = []
    private var files: [[String: String]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "Sending to Markette…"
        label.font = .preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        Task { await collect() }
    }

    private func collect() async {
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let title = items.first?.attributedContentText?.string ?? items.first?.attributedTitle?.string ?? ""
        for item in items {
            for provider in item.attachments ?? [] {
                await handle(provider)
            }
        }
        save(title: title)
        openApp()
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func handle(_ provider: NSItemProvider) async {
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            await copyFile(provider, type: .movie, fallbackMime: "video/mp4")
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            await copyFile(provider, type: .image, fallbackMime: "image/jpeg")
        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL,
               !url.isFileURL {
                texts.append(url.absoluteString)
            }
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                texts.append(text)
            }
        }
    }

    /// Copies the shared file into the App Group container so the app can read and upload it.
    private func copyFile(_ provider: NSItemProvider, type: UTType, fallbackMime: String) async {
        guard let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("shared", isDirectory: true) else { return }
        try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)

        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
                defer { done.resume() }
                guard let url else { return }
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                guard size <= self.maxFileBytes else { return }
                let ext = url.pathExtension.isEmpty ? (type == .movie ? "mp4" : "jpg") : url.pathExtension
                let dest = container.appendingPathComponent("\(UUID().uuidString).\(ext)")
                do {
                    try FileManager.default.copyItem(at: url, to: dest)
                } catch {
                    return
                }
                let mime = UTType(filenameExtension: ext)?.preferredMIMEType ?? fallbackMime
                self.files.append(["uri": dest.absoluteString, "name": url.lastPathComponent, "mimeType": mime])
            }
        }
    }

    private func save(title: String) {
        let data: [String: Any] = ["title": title, "texts": texts, "files": files]
        let defaults = UserDefaults(suiteName: appGroupId)
        defaults?.set(data, forKey: "share-target-data")
        defaults?.synchronize()
    }

    /// Share extensions cannot open their app officially; walk the responder chain to the
    /// UIApplication. If that fails, the plugin still picks the share up the next time
    /// Markette becomes active.
    private func openApp() {
        var responder: UIResponder? = self
        while let current = responder {
            if let app = current as? UIApplication {
                app.open(appURL, options: [:], completionHandler: nil)
                return
            }
            responder = current.next
        }
    }
}
