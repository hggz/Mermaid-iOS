// MermaidSwift - Pure Swift Mermaid Diagram Renderer
// No WKWebView, no JavaScript — CoreGraphics only

import Foundation

/// The top-level namespace for diagram model types.
/// All diagram types conform to the `Diagram` protocol.

// MARK: - Diagram Protocol

/// A parsed diagram that can be laid out and rendered.
protocol Diagram {
    var type: DiagramType { get }
}

enum DiagramType: String, Equatable {
    case flowchart
    case sequenceDiagram = "sequenceDiagram"
    case pie
    case unknown
}

// MARK: - Flowchart

struct FlowchartDiagram: Diagram {
    let type: DiagramType = .flowchart
    let direction: FlowDirection
    var nodes: [FlowNode]
    var edges: [FlowEdge]

    enum FlowDirection: String {
        case topToBottom = "TD"
        case topDown = "TB"
        case bottomToTop = "BT"
        case leftToRight = "LR"
        case rightToLeft = "RL"
    }
}

struct FlowNode: Equatable, Hashable {
    let id: String
    let label: String
    let shape: NodeShape

    enum NodeShape: Equatable, Hashable {
        case rectangle       // [text]
        case roundedRect     // (text)
        case stadium         // ([text])
        case diamond         // {text}
        case hexagon         // {{text}}
        case circle          // ((text))
        case asymmetric      // >text]
    }
}

struct FlowEdge: Equatable {
    let from: String
    let to: String
    let label: String?
    let style: EdgeStyle

    enum EdgeStyle: Equatable {
        case solid       // -->
        case dotted      // -.->
        case thick       // ==>
        case invisible   // ~~~
    }
}

// MARK: - Sequence Diagram

struct SequenceDiagram: Diagram {
    let type: DiagramType = .sequenceDiagram
    var participants: [Participant]
    var messages: [Message]
}

struct Participant: Equatable, Hashable {
    let id: String
    let label: String
}

struct Message: Equatable {
    let from: String
    let to: String
    let text: String
    let style: MessageStyle

    enum MessageStyle: Equatable {
        case solidArrow        // ->>
        case dottedArrow       // -->>
        case solidLine         // ->
        case dottedLine        // -->
        case solidCross        // -x
        case dottedCross       // --x
    }
}

// MARK: - Pie Chart

struct PieChartDiagram: Diagram {
    let type: DiagramType = .pie
    let title: String?
    var slices: [PieSlice]
}

struct PieSlice: Equatable {
    let label: String
    let value: Double
}
