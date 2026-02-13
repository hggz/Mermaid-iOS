import SwiftUI
import CoreTransferable

enum RenderEngine: String, CaseIterable {
    case swift = "Swift (Native)"
    case webView = "WKWebView (JS)"
}

struct ContentView: View {
    @State private var diagramText: String = Self.sampleDiagram
    @State private var renderedImage: UIImage?
    @State private var isRendering = false
    @State private var errorMessage: String?
    @State private var showExportSheet = false
    @State private var showSavedAlert = false
    @State private var renderEngine: RenderEngine = .swift
    @State private var renderTime: TimeInterval = 0

    private let webRenderer = MermaidRenderer()
    private let swiftRenderer = MermaidSwift()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Editor section
                editorSection

                Divider()

                // Toolbar
                toolbarSection

                Divider()

                // Preview section
                previewSection
            }
            .navigationTitle("Mermaid Renderer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(DiagramTemplate.allCases, id: \.self) { template in
                            Button(template.rawValue) {
                                diagramText = template.code
                            }
                        }
                    } label: {
                        Label("Templates", systemImage: "doc.text")
                    }
                }
            }
            .alert("Saved!", isPresented: $showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Image saved to Photos")
            }
        }
    }

    // MARK: - Subviews

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Picker("Engine", selection: $renderEngine) {
                    ForEach(RenderEngine.allCases, id: \.self) { engine in
                        Text(engine.rawValue).tag(engine)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
                Spacer()
                if renderTime > 0 {
                    Text(String(format: "%.0fms", renderTime * 1000))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            TextEditor(text: $diagramText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .frame(minHeight: 120, maxHeight: 200)
        }
    }

    private var toolbarSection: some View {
        HStack(spacing: 12) {
            Button {
                Task { await renderDiagram() }
            } label: {
                HStack(spacing: 6) {
                    if isRendering {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(isRendering ? "Rendering…" : "Render")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRendering || diagramText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if renderedImage != nil {
                Button {
                    exportToPNG()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save PNG")
                    }
                }
                .buttonStyle(.bordered)

                if let pngData = renderedImage?.pngData(),
                   let url = saveTempPNG(pngData) {
                    ShareLink(item: url, preview: SharePreview("Mermaid Diagram")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var previewSection: some View {
        Group {
            if let errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if let renderedImage {
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: renderedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.artframe")
                        .font(.largeTitle)
                        .foregroundStyle(.quaternary)
                    Text("Tap Render to preview")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Actions

    private func renderDiagram() async {
        isRendering = true
        errorMessage = nil
        renderTime = 0

        let start = CFAbsoluteTimeGetCurrent()

        do {
            switch renderEngine {
            case .swift:
                let cgImage = try swiftRenderer.render(diagramText)
                renderedImage = UIImage(cgImage: cgImage)
            case .webView:
                renderedImage = try await webRenderer.render(diagram: diagramText)
            }
            renderTime = CFAbsoluteTimeGetCurrent() - start
        } catch {
            errorMessage = error.localizedDescription
            renderedImage = nil
            renderTime = CFAbsoluteTimeGetCurrent() - start
        }

        isRendering = false
    }

    private func exportToPNG() {
        guard let image = renderedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showSavedAlert = true
    }

    private func saveTempPNG(_ data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mermaid-diagram.png")
        try? data.write(to: url)
        return url
    }

    // MARK: - Sample

    static let sampleDiagram = """
    sequenceDiagram
        participant Client
        participant Server
        participant Database
        Client->>Server: HTTP Request
        Server->>Database: Query
        Database-->>Server: Results
        Server-->>Client: HTTP Response
    """
}

// MARK: - Templates

enum DiagramTemplate: String, CaseIterable {
    case sequence = "Sequence Diagram"
    case flowchart = "Flowchart"
    case classDiagram = "Class Diagram"
    case stateDiagram = "State Diagram"
    case gantt = "Gantt Chart"
    case pie = "Pie Chart"

    var code: String {
        switch self {
        case .sequence:
            return """
            sequenceDiagram
                participant Alice
                participant Bob
                participant Charlie
                Alice->>Bob: Hello Bob, how are you?
                Bob-->>Alice: Great!
                Alice->>Charlie: Hello Charlie
                Charlie-->>Alice: Hi Alice
                Bob->>Charlie: Hey Charlie
                Charlie-->>Bob: What's up?
            """
        case .flowchart:
            return """
            flowchart TD
                A[Start] --> B{Is it working?}
                B -->|Yes| C[Great!]
                B -->|No| D[Debug]
                D --> E[Fix the code]
                E --> B
                C --> F[Deploy]
                F --> G[End]
            """
        case .classDiagram:
            return """
            classDiagram
                class Animal {
                    +String name
                    +int age
                    +makeSound()
                }
                class Dog {
                    +String breed
                    +fetch()
                }
                class Cat {
                    +bool isIndoor
                    +purr()
                }
                Animal <|-- Dog
                Animal <|-- Cat
            """
        case .stateDiagram:
            return """
            stateDiagram-v2
                [*] --> Idle
                Idle --> Loading: fetch
                Loading --> Success: data received
                Loading --> Error: request failed
                Error --> Loading: retry
                Success --> Idle: reset
                Error --> Idle: dismiss
            """
        case .gantt:
            return """
            gantt
                title Project Timeline
                dateFormat YYYY-MM-DD
                section Design
                    Wireframes     :a1, 2024-01-01, 7d
                    Mockups        :a2, after a1, 5d
                section Development
                    Frontend       :b1, after a2, 14d
                    Backend        :b2, after a2, 10d
                section Testing
                    QA             :c1, after b1, 7d
                    UAT            :c2, after c1, 5d
            """
        case .pie:
            return """
            pie title Language Distribution
                "Swift" : 45
                "Objective-C" : 25
                "JavaScript" : 15
                "Python" : 10
                "Other" : 5
            """
        }
    }
}

#Preview {
    ContentView()
}
