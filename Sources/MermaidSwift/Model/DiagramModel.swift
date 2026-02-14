// MermaidSwift - Pure Swift Mermaid Diagram Renderer
// No WKWebView, no JavaScript — CoreGraphics only

import Foundation

// MARK: - Diagram Protocol

/// A parsed diagram that can be laid out and rendered.
public protocol Diagram {
    var type: DiagramType { get }
}

public enum DiagramType: String, Equatable, Sendable {
    case flowchart
    case sequenceDiagram = "sequenceDiagram"
    case pie
    case classDiagram = "classDiagram"
    case stateDiagram = "stateDiagram"
    case gantt
    case erDiagram = "erDiagram"
    case unknown
}

// MARK: - Flowchart

public struct FlowchartDiagram: Diagram {
    public let type: DiagramType = .flowchart
    public let direction: FlowDirection
    public var nodes: [FlowNode]
    public var edges: [FlowEdge]
    public var subgraphs: [Subgraph]
    public var classDefs: [String: NodeStyle]
    public var nodeClassMap: [String: String]  // nodeId -> className

    public init(direction: FlowDirection, nodes: [FlowNode], edges: [FlowEdge],
                subgraphs: [Subgraph] = [], classDefs: [String: NodeStyle] = [:],
                nodeClassMap: [String: String] = [:]) {
        self.direction = direction
        self.nodes = nodes
        self.edges = edges
        self.subgraphs = subgraphs
        self.classDefs = classDefs
        self.nodeClassMap = nodeClassMap
    }

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

public struct Subgraph: Equatable, Sendable {
    public let id: String
    public let label: String
    public var nodeIds: [String]

    public init(id: String, label: String, nodeIds: [String] = []) {
        self.id = id
        self.label = label
        self.nodeIds = nodeIds
    }
}

public struct NodeStyle: Equatable, Sendable {
    public var fill: String?
    public var stroke: String?
    public var strokeWidth: CGFloat?
    public var color: String?

    public init(fill: String? = nil, stroke: String? = nil,
                strokeWidth: CGFloat? = nil, color: String? = nil) {
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
        self.color = color
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

// MARK: - Class Diagram

public struct ClassDiagram: Diagram {
    public let type: DiagramType = .classDiagram
    public var classes: [ClassDefinition]
    public var relationships: [ClassRelationship]

    public init(classes: [ClassDefinition] = [], relationships: [ClassRelationship] = []) {
        self.classes = classes
        self.relationships = relationships
    }
}

public struct ClassDefinition: Equatable, Sendable {
    public let name: String
    public var properties: [ClassMember]
    public var methods: [ClassMember]
    public var annotation: String?

    public init(name: String, properties: [ClassMember] = [], methods: [ClassMember] = [],
                annotation: String? = nil) {
        self.name = name
        self.properties = properties
        self.methods = methods
        self.annotation = annotation
    }
}

public struct ClassMember: Equatable, Sendable {
    public let visibility: Visibility
    public let name: String
    public let memberType: String?

    public init(visibility: Visibility = .public, name: String, memberType: String? = nil) {
        self.visibility = visibility
        self.name = name
        self.memberType = memberType
    }

    public enum Visibility: String, Equatable, Sendable {
        case `public` = "+"
        case `private` = "-"
        case protected = "#"
        case packagePrivate = "~"
    }
}

public struct ClassRelationship: Equatable, Sendable {
    public let from: String
    public let to: String
    public let label: String?
    public let relationshipType: ClassRelationType
    public let fromCardinality: String?
    public let toCardinality: String?

    public init(from: String, to: String, label: String? = nil,
                relationshipType: ClassRelationType, fromCardinality: String? = nil,
                toCardinality: String? = nil) {
        self.from = from
        self.to = to
        self.label = label
        self.relationshipType = relationshipType
        self.fromCardinality = fromCardinality
        self.toCardinality = toCardinality
    }

    public enum ClassRelationType: String, Equatable, Sendable {
        case inheritance       // <|--
        case composition       // *--
        case aggregation       // o--
        case association       // -->
        case dependency        // ..>
        case realization       // ..|>
    }
}

// MARK: - State Diagram

public struct StateDiagram: Diagram {
    public let type: DiagramType = .stateDiagram
    public var states: [StateNode]
    public var transitions: [StateTransition]

    public init(states: [StateNode] = [], transitions: [StateTransition] = []) {
        self.states = states
        self.transitions = transitions
    }
}

public struct StateNode: Equatable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let description: String?

    public init(id: String, label: String? = nil, description: String? = nil) {
        self.id = id
        self.label = label ?? id
        self.description = description
    }
}

public struct StateTransition: Equatable, Sendable {
    public let from: String
    public let to: String
    public let label: String?

    public init(from: String, to: String, label: String? = nil) {
        self.from = from
        self.to = to
        self.label = label
    }
}

// MARK: - Gantt Chart

public struct GanttDiagram: Diagram {
    public let type: DiagramType = .gantt
    public let title: String?
    public let dateFormat: String?
    public var sections: [GanttSection]

    public init(title: String? = nil, dateFormat: String? = nil, sections: [GanttSection] = []) {
        self.title = title
        self.dateFormat = dateFormat
        self.sections = sections
    }
}

public struct GanttSection: Equatable, Sendable {
    public let name: String
    public var tasks: [GanttTask]

    public init(name: String, tasks: [GanttTask] = []) {
        self.name = name
        self.tasks = tasks
    }
}

public struct GanttTask: Equatable, Sendable {
    public let name: String
    public let id: String?
    public let status: TaskStatus
    public let startDate: String?
    public let duration: String?
    public let afterId: String?

    public init(name: String, id: String? = nil, status: TaskStatus = .normal,
                startDate: String? = nil, duration: String? = nil, afterId: String? = nil) {
        self.name = name
        self.id = id
        self.status = status
        self.startDate = startDate
        self.duration = duration
        self.afterId = afterId
    }

    public enum TaskStatus: String, Equatable, Sendable {
        case normal
        case done
        case active
        case critical
        case criticalDone = "crit,done"
        case criticalActive = "crit,active"
    }
}

// MARK: - ER Diagram

public struct ERDiagram: Diagram {
    public let type: DiagramType = .erDiagram
    public var entities: [EREntity]
    public var relationships: [ERRelationship]

    public init(entities: [EREntity] = [], relationships: [ERRelationship] = []) {
        self.entities = entities
        self.relationships = relationships
    }
}

public struct EREntity: Equatable, Sendable {
    public let name: String
    public var attributes: [ERAttribute]

    public init(name: String, attributes: [ERAttribute] = []) {
        self.name = name
        self.attributes = attributes
    }
}

public struct ERAttribute: Equatable, Sendable {
    public let attributeType: String
    public let name: String
    public let key: AttributeKey?

    public init(attributeType: String, name: String, key: AttributeKey? = nil) {
        self.attributeType = attributeType
        self.name = name
        self.key = key
    }

    public enum AttributeKey: String, Equatable, Sendable {
        case pk = "PK"
        case fk = "FK"
        case uk = "UK"
    }
}

public struct ERRelationship: Equatable, Sendable {
    public let from: String
    public let to: String
    public let label: String
    public let fromCardinality: ERCardinality
    public let toCardinality: ERCardinality

    public init(from: String, to: String, label: String,
                fromCardinality: ERCardinality, toCardinality: ERCardinality) {
        self.from = from
        self.to = to
        self.label = label
        self.fromCardinality = fromCardinality
        self.toCardinality = toCardinality
    }

    public enum ERCardinality: String, Equatable, Sendable {
        case exactlyOne = "||"
        case zeroOrOne = "|o"
        case zeroOrMore = "o{"
        case oneOrMore = "}|"
    }
}
