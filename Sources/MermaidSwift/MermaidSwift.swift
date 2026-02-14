import CoreGraphics
import Foundation

/// Pure Swift Mermaid diagram renderer.
///
/// Parses Mermaid DSL → lays out diagram → renders to CGImage via CoreGraphics.
/// No WKWebView, no JavaScript dependencies.
///
/// Usage:
/// ```swift
/// let mermaid = MermaidSwift()
/// let image = try mermaid.render("flowchart TD\n  A[Start] --> B[End]")
/// let pngData = try mermaid.renderToPNG("sequenceDiagram\n  Alice->>Bob: Hello")
///
/// // Dark mode
/// let darkMermaid = MermaidSwift(config: .darkMode)
/// let darkImage = try darkMermaid.renderToPNG("pie title Usage\n  \"A\" : 30\n  \"B\" : 70")
/// ```
public struct MermaidSwift {

    private let parser = MermaidParser()
    private let layoutEngine: DiagramLayout
    private let renderer: DiagramRenderer

    public init(config: LayoutConfig = .default) {
        self.layoutEngine = DiagramLayout(config: config)
        self.renderer = DiagramRenderer(config: config)
    }

    /// Create a dark-mode renderer.
    public static var darkMode: MermaidSwift {
        MermaidSwift(config: .darkMode)
    }

    /// Parse and render a Mermaid DSL string to a CGImage.
    public func render(_ input: String) throws -> CGImage {
        let diagram = try parser.parse(input)
        return try renderDiagram(diagram)
    }

    /// Parse and render a Mermaid DSL string to PNG data.
    public func renderToPNG(_ input: String) throws -> Data {
        let image = try render(input)
        guard let data = DiagramRenderer.pngData(from: image) else {
            throw MermaidSwiftError.pngConversionFailed
        }
        return data
    }

    /// Parse only — returns the diagram model without rendering.
    public func parse(_ input: String) throws -> Diagram {
        try parser.parse(input)
    }

    // MARK: - Private

    private func renderDiagram(_ diagram: Diagram) throws -> CGImage {
        switch diagram {
        case let flowchart as FlowchartDiagram:
            let layout = layoutEngine.layoutFlowchart(flowchart)
            guard let image = renderer.renderFlowchart(layout) else {
                throw MermaidSwiftError.renderFailed
            }
            return image

        case let sequence as SequenceDiagram:
            let layout = layoutEngine.layoutSequenceDiagram(sequence)
            guard let image = renderer.renderSequenceDiagram(layout) else {
                throw MermaidSwiftError.renderFailed
            }
            return image

        case let pie as PieChartDiagram:
            let layout = layoutEngine.layoutPieChart(pie)
            guard let image = renderer.renderPieChart(layout) else {
                throw MermaidSwiftError.renderFailed
            }
            return image

        case let classDiagram as ClassDiagram:
            let layout = layoutEngine.layoutClassDiagram(classDiagram)
            guard let image = renderer.renderClassDiagram(layout) else {
                throw MermaidSwiftError.renderFailed
            }
            return image

        case let stateDiagram as StateDiagram:
            let layout = layoutEngine.layoutStateDiagram(stateDiagram)
            guard let image = renderer.renderStateDiagram(layout) else {
                throw MermaidSwiftError.renderFailed
            }
            return image

        case let gantt as GanttDiagram:
            let layout = layoutEngine.layoutGanttChart(gantt)
            guard let image = renderer.renderGanttChart(layout) else {
                throw MermaidSwiftError.renderFailed
            }
            return image

        case let er as ERDiagram:
            let layout = layoutEngine.layoutERDiagram(er)
            guard let image = renderer.renderERDiagram(layout) else {
                throw MermaidSwiftError.renderFailed
            }
            return image

        default:
            throw MermaidSwiftError.unsupportedDiagramType
        }
    }
}

// MARK: - Errors

public enum MermaidSwiftError: LocalizedError {
    case renderFailed
    case pngConversionFailed
    case unsupportedDiagramType

    public var errorDescription: String? {
        switch self {
        case .renderFailed:
            return "Failed to render diagram to image"
        case .pngConversionFailed:
            return "Failed to convert CGImage to PNG data"
        case .unsupportedDiagramType:
            return "Unsupported diagram type"
        }
    }
}
