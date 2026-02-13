import WebKit
import UIKit

/// Renders Mermaid diagram markup to a UIImage using an offscreen WKWebView.
///
/// Uses the bundled `mermaid.min.js` (IIFE bundle) inside a WKWebView to parse
/// diagram DSL → generate SVG → snapshot to image. This replicates mmdc (Mermaid CLI)
/// natively on iOS.
final class MermaidRenderer: NSObject {

    enum RenderError: LocalizedError {
        case mermaidJSNotFound
        case renderFailed(String)
        case snapshotFailed
        case timeout

        var errorDescription: String? {
            switch self {
            case .mermaidJSNotFound:
                return "mermaid.min.js not found in app bundle"
            case .renderFailed(let message):
                return "Mermaid render error: \(message)"
            case .snapshotFailed:
                return "Failed to take WKWebView snapshot"
            case .timeout:
                return "Render timed out"
            }
        }
    }

    struct RenderOptions {
        var theme: String = "default"
        var backgroundColor: String = "white"
        var maxWidth: CGFloat = 1200
        var padding: CGFloat = 16
        var scale: CGFloat = 2.0 // retina

        static let `default` = RenderOptions()
    }

    // MARK: - Public API

    /// Render a Mermaid diagram string to a UIImage.
    ///
    /// - Parameters:
    ///   - diagram: The Mermaid DSL string (e.g. `sequenceDiagram\n  Alice->>Bob: Hello`)
    ///   - options: Rendering configuration (theme, background, scale, etc.)
    /// - Returns: A rendered UIImage of the diagram
    func render(diagram: String, options: RenderOptions = .default) async throws -> UIImage {
        guard let mermaidJSURL = Bundle.main.url(forResource: "mermaid.min", withExtension: "js"),
              let mermaidJS = try? String(contentsOf: mermaidJSURL, encoding: .utf8) else {
            throw RenderError.mermaidJSNotFound
        }

        let escapedDiagram = escapeDiagramForJS(diagram)

        let html = buildHTML(
            mermaidJS: mermaidJS,
            diagram: escapedDiagram,
            options: options
        )

        return try await renderInWebView(html: html, options: options)
    }

    // MARK: - Private

    private func escapeDiagramForJS(_ diagram: String) -> String {
        diagram
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "")
    }

    private func buildHTML(mermaidJS: String, diagram: String, options: RenderOptions) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    background: \(options.backgroundColor);
                    padding: \(Int(options.padding))px;
                    display: flex;
                    justify-content: center;
                    align-items: flex-start;
                }
                #container {
                    display: inline-block;
                    max-width: \(Int(options.maxWidth))px;
                }
                #container svg {
                    max-width: 100%;
                    height: auto;
                }
            </style>
        </head>
        <body>
            <div id="container"></div>
            <script>\(mermaidJS)</script>
            <script>
                (async function() {
                    try {
                        mermaid.initialize({
                            startOnLoad: false,
                            theme: '\(options.theme)',
                            securityLevel: 'loose'
                        });
                        const { svg } = await mermaid.render('diagram', `\(diagram)`);
                        document.getElementById('container').innerHTML = svg;

                        // Wait a tick for layout
                        await new Promise(r => setTimeout(r, 100));

                        const svgEl = document.querySelector('#container svg');
                        const rect = svgEl.getBoundingClientRect();
                        window.webkit.messageHandlers.renderComplete.postMessage(
                            JSON.stringify({
                                width: Math.ceil(rect.width),
                                height: Math.ceil(rect.height)
                            })
                        );
                    } catch (err) {
                        window.webkit.messageHandlers.renderError.postMessage(
                            err.message || String(err)
                        );
                    }
                })();
            </script>
        </body>
        </html>
        """
    }

    @MainActor
    private func renderInWebView(html: String, options: RenderOptions) async throws -> UIImage {
        // Initial size — will be adjusted after mermaid renders
        let initialSize = CGSize(width: options.maxWidth + options.padding * 2, height: 800)

        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: CGRect(origin: .zero, size: initialSize), configuration: config)
        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = false

        // Attach to key window so WKWebView actually renders
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            webView.frame = CGRect(x: -9999, y: -9999, width: initialSize.width, height: initialSize.height)
            window.addSubview(webView)
        }

        defer {
            webView.removeFromSuperview()
            config.userContentController.removeAllScriptMessageHandlers()
        }

        let image: UIImage = try await withCheckedThrowingContinuation { continuation in
            let coordinator = RenderCoordinator(
                webView: webView,
                scale: options.scale,
                continuation: continuation
            )
            config.userContentController.add(coordinator, name: "renderComplete")
            config.userContentController.add(coordinator, name: "renderError")

            webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)

            // Timeout after 15 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak coordinator] in
                coordinator?.timeoutIfNeeded()
            }
        }

        return image
    }
}

// MARK: - RenderCoordinator

/// Bridges WKScriptMessageHandler callbacks to Swift async continuation.
private final class RenderCoordinator: NSObject, WKScriptMessageHandler {
    private let webView: WKWebView
    private let scale: CGFloat
    private var continuation: CheckedContinuation<UIImage, Error>?

    init(webView: WKWebView, scale: CGFloat, continuation: CheckedContinuation<UIImage, Error>) {
        self.webView = webView
        self.scale = scale
        self.continuation = continuation
    }

    func timeoutIfNeeded() {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(throwing: MermaidRenderer.RenderError.timeout)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let cont = continuation else { return }
        continuation = nil

        if message.name == "renderComplete" {
            handleRenderComplete(message: message, continuation: cont)
        } else if message.name == "renderError" {
            let errorMsg = message.body as? String ?? "Unknown render error"
            cont.resume(throwing: MermaidRenderer.RenderError.renderFailed(errorMsg))
        }
    }

    private func handleRenderComplete(
        message: WKScriptMessage,
        continuation: CheckedContinuation<UIImage, Error>
    ) {
        // Parse dimensions from JS
        var snapshotWidth: CGFloat = webView.frame.width
        var snapshotHeight: CGFloat = webView.frame.height

        if let jsonString = message.body as? String,
           let data = jsonString.data(using: .utf8),
           let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let w = info["width"] as? CGFloat { snapshotWidth = w + 32 } // padding
            if let h = info["height"] as? CGFloat { snapshotHeight = h + 32 }
        }

        // Resize webView to fit the rendered SVG
        webView.frame.size = CGSize(width: snapshotWidth, height: snapshotHeight)

        // Short delay for re-layout, then snapshot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [webView, scale] in
            let snapshotConfig = WKSnapshotConfiguration()
            snapshotConfig.snapshotWidth = NSNumber(value: Double(snapshotWidth / scale * scale))

            webView.takeSnapshot(with: snapshotConfig) { image, error in
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(
                        throwing: error ?? MermaidRenderer.RenderError.snapshotFailed
                    )
                }
            }
        }
    }
}
