// MermaidSwift - Pure Swift Mermaid Diagram Renderer
// No WKWebView, no JavaScript — CoreGraphics only

import Foundation

/// The top-level namespace for diagram model types.
/// All diagram types conform to the `Diagram` protocol.

// MARK: - Diagram Protocol

/// A parsed diagram that can be laid out and rendered.
public protocol Diagram {
    var type: DiagramType { get }
}

public enum DiagramType: String, Equatable, Sendable {
    case flowchart
    case sequenceDiagram = "sequenceDiagram"
    case pie
    case unknown
}

// MARK: - Flowchart

public struct FlowchartDiagram: Diagram {
    public let type: DiagramType = .flowchart
    public let direction: FlowDirection
    public var nodes: [FlowNode]
    public var edges: [FlowEdge]

    public enum FlowDirection: String {
        case topToBottom = "TD"
        case topDown = "TB"
        case bottomToTop = "BT"
        case leftToRight = "LR"
        case rightToLeft = "RL"
    }
}

public struct FlowNode: Equatable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let shape: NodeShape

    public enum NodeShape: Equatable, Hashable, Sendable {
        case rectangle       // [text]
        case roundedRect     // (text)
        case stadium         // ([text])
        case diamond         // {text}
        case hexagon         // {{text}}
        case circle          // ((text))
        case asymmetric      // >text]
    }
}

public struct FlowEdge: Equatable, Sendable {
    public let from: String
    public let to: String
    public let label: String?
    public let style: EdgeStyle

    public enum EdgeStyle: Equatable, Sendable {
        case solid       // -->
        case dotted      // -.->
        case thick       // ==>
        case invisible   // ~~~
    }
}

// MARK: - Sequence Diagram

public struct SequenceDiagram: Diagram {
    public let type: DiagramType = .sequenceDiagram
    public var participants: [Participant]
    public var messages: [Message]
}

public struct Participant: Equatable, Hashable, Sendable {
    public let id: String
    public let label: String
}

public struct Message: Equatable, Sendable {
    public let from: String
    public let to: String
    public let text: String
    public let style: MessageStyle

    public enum MessageStyle: Equatable, Sendable {
        case solidArrow        // ->>
        case dottedArrow       // -->>
        case solidLine         // ->
        case dottedLine        // -->
        case solidCross        // -x
        case dottedCross       // --x
    }
}

// MARK: - Pie Chart

public struct PieChartDiagram: Diagram {
    public let type: DiagramType = .pie
    public let title: String?
    public var slices: [PieSlice]
}

public struct PieSlice: Equatable, Sendable {
    public let label: String
    public let value: Double
}
