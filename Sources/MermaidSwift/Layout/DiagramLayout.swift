import CoreGraphics
import Foundation

/// Layout configuration for diagram rendering.
public struct LayoutConfig {
    // General
    public var padding: CGFloat = 40
    public var backgroundColor: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

    // Fonts
    public var fontSize: CGFloat = 14
    public var titleFontSize: CGFloat = 18
    public var fontName: String = "Helvetica"
    public var boldFontName: String = "Helvetica-Bold"

    // Colors
    public var nodeColor: CGColor = CGColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1)
    public var nodeBorderColor: CGColor = CGColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1)
    public var edgeColor: CGColor = CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
    public var textColor: CGColor = CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
    public var arrowColor: CGColor = CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)

    // Flowchart
    public var nodeWidth: CGFloat = 150
    public var nodeHeight: CGFloat = 50
    public var nodeCornerRadius: CGFloat = 8
    public var horizontalSpacing: CGFloat = 60
    public var verticalSpacing: CGFloat = 60
    public var lineWidth: CGFloat = 2

    // Sequence diagram
    public var participantWidth: CGFloat = 120
    public var participantHeight: CGFloat = 40
    public var participantSpacing: CGFloat = 40
    public var messageSpacing: CGFloat = 50
    public var lifelineColor: CGColor = CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)

    // Pie chart
    public var pieRadius: CGFloat = 120
    public var pieLabelOffset: CGFloat = 30
    public var pieColors: [CGColor] = [
        CGColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1),
        CGColor(red: 0.92, green: 0.34, blue: 0.34, alpha: 1),
        CGColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1),
        CGColor(red: 1.00, green: 0.76, blue: 0.03, alpha: 1),
        CGColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1),
        CGColor(red: 1.00, green: 0.60, blue: 0.00, alpha: 1),
        CGColor(red: 0.00, green: 0.74, blue: 0.83, alpha: 1),
        CGColor(red: 0.91, green: 0.47, blue: 0.62, alpha: 1),
    ]

    // Subgraph
    public var subgraphPadding: CGFloat = 20
    public var subgraphLabelHeight: CGFloat = 24
    public var subgraphBorderColor: CGColor = CGColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
    public var subgraphFillColor: CGColor = CGColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 0.5)

    // Class diagram
    public var classBoxWidth: CGFloat = 200
    public var classHeaderHeight: CGFloat = 35
    public var classMemberHeight: CGFloat = 22
    public var classSpacing: CGFloat = 80

    // State diagram
    public var stateWidth: CGFloat = 140
    public var stateHeight: CGFloat = 45
    public var stateCornerRadius: CGFloat = 12
    public var stateSpacing: CGFloat = 70
    public var startEndRadius: CGFloat = 12

    // Gantt chart
    public var ganttBarHeight: CGFloat = 28
    public var ganttBarSpacing: CGFloat = 8
    public var ganttSectionSpacing: CGFloat = 12
    public var ganttLabelWidth: CGFloat = 180
    public var ganttDayWidth: CGFloat = 30
    public var ganttColors: [CGColor] = [
        CGColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1),
        CGColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1),
        CGColor(red: 0.92, green: 0.34, blue: 0.34, alpha: 1),
        CGColor(red: 1.00, green: 0.76, blue: 0.03, alpha: 1),
    ]
    public var ganttCriticalColor: CGColor = CGColor(red: 0.92, green: 0.34, blue: 0.34, alpha: 1)
    public var ganttDoneColor: CGColor = CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
    public var ganttActiveColor: CGColor = CGColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1)

    // ER diagram
    public var erEntityWidth: CGFloat = 180
    public var erEntityHeaderHeight: CGFloat = 32
    public var erAttributeHeight: CGFloat = 22
    public var erEntitySpacing: CGFloat = 100

    public init() {}

    public static let `default` = LayoutConfig()

    /// Dark mode configuration
    public static var darkMode: LayoutConfig {
        var config = LayoutConfig()
        config.backgroundColor = CGColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
        config.textColor = CGColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1)
        config.nodeColor = CGColor(red: 0.2, green: 0.25, blue: 0.35, alpha: 1)
        config.nodeBorderColor = CGColor(red: 0.4, green: 0.55, blue: 0.8, alpha: 1)
        config.edgeColor = CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        config.arrowColor = CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        config.lifelineColor = CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        config.subgraphBorderColor = CGColor(red: 0.45, green: 0.5, blue: 0.55, alpha: 1)
        config.subgraphFillColor = CGColor(red: 0.18, green: 0.2, blue: 0.24, alpha: 0.6)
        return config
    }
}

// MARK: - Layout Result Types

struct PositionedNode {
    let node: FlowNode
    let frame: CGRect
    let style: NodeStyle?
}

struct PositionedEdge {
    let edge: FlowEdge
    let points: [CGPoint]  // Multi-point path for edge routing
    let labelPosition: CGPoint?
}

struct PositionedSubgraph {
    let subgraph: Subgraph
    let frame: CGRect
    let labelPosition: CGPoint
}

struct PositionedParticipant {
    let participant: Participant
    let headerFrame: CGRect
    let lifelineX: CGFloat
    let lifelineTop: CGFloat
    let lifelineBottom: CGFloat
}

struct PositionedMessage {
    let message: Message
    let fromX: CGFloat
    let toX: CGFloat
    let y: CGFloat
}

struct PositionedPieSlice {
    let slice: PieSlice
    let startAngle: CGFloat
    let endAngle: CGFloat
    let color: CGColor
    let labelPosition: CGPoint
    let percentage: CGFloat
}

struct PositionedClassBox {
    let classDef: ClassDefinition
    let frame: CGRect
    let headerFrame: CGRect
    let propertiesFrame: CGRect
    let methodsFrame: CGRect
}

struct PositionedClassRelationship {
    let relationship: ClassRelationship
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let fromLabelPos: CGPoint?
    let toLabelPos: CGPoint?
    let labelPos: CGPoint?
}

struct PositionedState {
    let state: StateNode
    let frame: CGRect
    let isStartEnd: Bool
}

struct PositionedStateTransition {
    let transition: StateTransition
    let points: [CGPoint]
    let labelPosition: CGPoint?
}

struct PositionedGanttTask {
    let task: GanttTask
    let bar: CGRect
    let labelPosition: CGPoint
    let color: CGColor
}

struct PositionedGanttSection {
    let name: String
    let y: CGFloat
}

struct PositionedEREntity {
    let entity: EREntity
    let frame: CGRect
    let headerFrame: CGRect
    let attributeFrames: [CGRect]
}

struct PositionedERRelationship {
    let relationship: ERRelationship
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let labelPosition: CGPoint
}

// MARK: - Layout Calculations

struct DiagramLayout {

    let config: LayoutConfig

    init(config: LayoutConfig = .default) {
        self.config = config
    }

    // MARK: - Flowchart Layout

    struct FlowchartLayout {
        let nodes: [PositionedNode]
        let edges: [PositionedEdge]
        let subgraphs: [PositionedSubgraph]
        let size: CGSize
    }

    func layoutFlowchart(_ diagram: FlowchartDiagram) -> FlowchartLayout {
        let orderedIds = topologicalSort(diagram)
        let layers = assignLayers(orderedIds, edges: diagram.edges)
        let nodeMap = Dictionary(uniqueKeysWithValues: diagram.nodes.map { ($0.id, $0) })

        let isVertical = diagram.direction == .topToBottom ||
                         diagram.direction == .topDown ||
                         diagram.direction == .bottomToTop

        var positioned: [String: PositionedNode] = [:]

        for (layerIndex, layer) in layers.enumerated() {
            for (nodeIndex, nodeId) in layer.enumerated() {
                guard let node = nodeMap[nodeId] else { continue }

                let x: CGFloat
                let y: CGFloat

                if isVertical {
                    x = config.padding + CGFloat(nodeIndex) * (config.nodeWidth + config.horizontalSpacing)
                    y = config.padding + CGFloat(layerIndex) * (config.nodeHeight + config.verticalSpacing)
                } else {
                    x = config.padding + CGFloat(layerIndex) * (config.nodeWidth + config.horizontalSpacing)
                    y = config.padding + CGFloat(nodeIndex) * (config.nodeHeight + config.verticalSpacing)
                }

                let frame = CGRect(x: x, y: y, width: config.nodeWidth, height: config.nodeHeight)
                let style = resolveNodeStyle(nodeId: nodeId, diagram: diagram)
                positioned[nodeId] = PositionedNode(node: node, frame: frame, style: style)
            }
        }

        // Layout subgraphs (bounding boxes around their nodes)
        let positionedSubgraphs = diagram.subgraphs.compactMap { sg -> PositionedSubgraph? in
            let nodeFrames = sg.nodeIds.compactMap { positioned[$0]?.frame }
            guard !nodeFrames.isEmpty else { return nil }

            let minX = nodeFrames.map(\.minX).min()! - config.subgraphPadding
            let minY = nodeFrames.map(\.minY).min()! - config.subgraphPadding - config.subgraphLabelHeight
            let maxX = nodeFrames.map(\.maxX).max()! + config.subgraphPadding
            let maxY = nodeFrames.map(\.maxY).max()! + config.subgraphPadding

            let frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            let labelPos = CGPoint(x: minX + config.subgraphPadding, y: minY + config.subgraphLabelHeight / 2 + 4)

            return PositionedSubgraph(subgraph: sg, frame: frame, labelPosition: labelPos)
        }

        // Edge routing with obstacle avoidance
        let allNodeFrames = positioned.values.map(\.frame)
        let positionedEdges = diagram.edges.compactMap { edge -> PositionedEdge? in
            guard let fromNode = positioned[edge.from],
                  let toNode = positioned[edge.to] else { return nil }

            let fromPoint: CGPoint
            let toPoint: CGPoint

            if isVertical {
                fromPoint = CGPoint(x: fromNode.frame.midX, y: fromNode.frame.maxY)
                toPoint = CGPoint(x: toNode.frame.midX, y: toNode.frame.minY)
            } else {
                fromPoint = CGPoint(x: fromNode.frame.maxX, y: fromNode.frame.midY)
                toPoint = CGPoint(x: toNode.frame.minX, y: toNode.frame.midY)
            }

            let routedPoints = routeEdge(
                from: fromPoint, to: toPoint,
                obstacles: allNodeFrames,
                excludeIds: [edge.from, edge.to],
                nodeFrames: positioned,
                isVertical: isVertical
            )

            let labelPos = edge.label != nil ?
                CGPoint(x: (fromPoint.x + toPoint.x) / 2, y: (fromPoint.y + toPoint.y) / 2 - 10) : nil

            return PositionedEdge(edge: edge, points: routedPoints, labelPosition: labelPos)
        }

        // Calculate total size, accounting for subgraphs
        var allFrames = positioned.values.map(\.frame)
        allFrames.append(contentsOf: positionedSubgraphs.map(\.frame))
        let maxX = (allFrames.map { $0.maxX }.max() ?? 0) + config.padding
        let maxY = (allFrames.map { $0.maxY }.max() ?? 0) + config.padding

        return FlowchartLayout(
            nodes: Array(positioned.values),
            edges: positionedEdges,
            subgraphs: positionedSubgraphs,
            size: CGSize(width: maxX, height: maxY)
        )
    }

    private func resolveNodeStyle(nodeId: String, diagram: FlowchartDiagram) -> NodeStyle? {
        guard let className = diagram.nodeClassMap[nodeId],
              let style = diagram.classDefs[className] else { return nil }
        return style
    }

    // MARK: - Edge Routing

    private func routeEdge(from: CGPoint, to: CGPoint, obstacles: [CGRect],
                           excludeIds: [String], nodeFrames: [String: PositionedNode],
                           isVertical: Bool) -> [CGPoint] {
        // Check if direct path intersects any obstacle
        let excludeFramesList = excludeIds.compactMap { nodeFrames[$0]?.frame }
        let intermediateObstacles = obstacles.filter { rect in
            !excludeFramesList.contains(where: { $0.equalTo(rect) }) &&
            lineIntersectsRect(from: from, to: to, rect: rect.insetBy(dx: -4, dy: -4))
        }

        if intermediateObstacles.isEmpty {
            return [from, to]
        }

        // Route around by adding bend points
        let offset: CGFloat = 20

        if isVertical {
            // Bend horizontally to avoid obstacles
            let obstacleMinX = intermediateObstacles.map(\.minX).min()!
            let obstacleMaxX = intermediateObstacles.map(\.maxX).max()!

            let bendX: CGFloat
            if abs(from.x - obstacleMinX) < abs(from.x - obstacleMaxX) {
                bendX = obstacleMinX - offset
            } else {
                bendX = obstacleMaxX + offset
            }

            return [from, CGPoint(x: bendX, y: from.y), CGPoint(x: bendX, y: to.y), to]
        } else {
            // Bend vertically to avoid obstacles
            let obstacleMinY = intermediateObstacles.map(\.minY).min()!
            let obstacleMaxY = intermediateObstacles.map(\.maxY).max()!

            let bendY: CGFloat
            if abs(from.y - obstacleMinY) < abs(from.y - obstacleMaxY) {
                bendY = obstacleMinY - offset
            } else {
                bendY = obstacleMaxY + offset
            }

            return [from, CGPoint(x: from.x, y: bendY), CGPoint(x: to.x, y: bendY), to]
        }
    }

    private func lineIntersectsRect(from: CGPoint, to: CGPoint, rect: CGRect) -> Bool {
        // Check if line segment from->to intersects the rectangle
        // Use Liang-Barsky algorithm simplified
        let dx = to.x - from.x
        let dy = to.y - from.y

        let edges: [(CGFloat, CGFloat)] = [
            (-dx, from.x - rect.minX),
            (dx, rect.maxX - from.x),
            (-dy, from.y - rect.minY),
            (dy, rect.maxY - from.y),
        ]

        var tMin: CGFloat = 0
        var tMax: CGFloat = 1

        for (p, q) in edges {
            if abs(p) < 0.001 {
                if q < 0 { return false }
            } else {
                let t = q / p
                if p < 0 {
                    tMin = max(tMin, t)
                } else {
                    tMax = min(tMax, t)
                }
                if tMin > tMax { return false }
            }
        }

        return true
    }

    private func topologicalSort(_ diagram: FlowchartDiagram) -> [String] {
        let allIds = Set(diagram.nodes.map(\.id))
        var inDegree: [String: Int] = Dictionary(uniqueKeysWithValues: allIds.map { ($0, 0) })
        var adjacency: [String: [String]] = [:]

        for edge in diagram.edges {
            adjacency[edge.from, default: []].append(edge.to)
            inDegree[edge.to, default: 0] += 1
        }

        var queue = allIds.filter { (inDegree[$0] ?? 0) == 0 }.sorted()
        var result: [String] = []

        while !queue.isEmpty {
            let node = queue.removeFirst()
            result.append(node)

            for neighbor in adjacency[node, default: []] {
                inDegree[neighbor, default: 0] -= 1
                if inDegree[neighbor] == 0 {
                    queue.append(neighbor)
                }
            }
        }

        let remaining = allIds.subtracting(result).sorted()
        result.append(contentsOf: remaining)

        return result
    }

    private func assignLayers(_ sortedIds: [String], edges: [FlowEdge]) -> [[String]] {
        var layerOf: [String: Int] = [:]

        for id in sortedIds {
            let incomingLayers = edges
                .filter { $0.to == id }
                .compactMap { layerOf[$0.from] }
            let layer = (incomingLayers.max() ?? -1) + 1
            layerOf[id] = layer
        }

        let maxLayer = layerOf.values.max() ?? 0
        var layers: [[String]] = Array(repeating: [], count: maxLayer + 1)
        for (id, layer) in layerOf {
            layers[layer].append(id)
        }

        for i in layers.indices {
            layers[i].sort()
        }

        return layers
    }

    // MARK: - Sequence Diagram Layout

    struct SequenceLayout {
        let participants: [PositionedParticipant]
        let messages: [PositionedMessage]
        let size: CGSize
    }

    func layoutSequenceDiagram(_ diagram: SequenceDiagram) -> SequenceLayout {
        let totalWidth = config.padding * 2 +
            CGFloat(diagram.participants.count) * config.participantWidth +
            CGFloat(max(0, diagram.participants.count - 1)) * config.participantSpacing

        let headerY = config.padding
        let lifelineTop = headerY + config.participantHeight + 20
        let lifelineBottom = lifelineTop + CGFloat(diagram.messages.count) * config.messageSpacing + 40

        var participantPositions: [PositionedParticipant] = []
        var participantXMap: [String: CGFloat] = [:]

        for (i, p) in diagram.participants.enumerated() {
            let x = config.padding + CGFloat(i) * (config.participantWidth + config.participantSpacing)
            let centerX = x + config.participantWidth / 2
            let headerFrame = CGRect(x: x, y: headerY, width: config.participantWidth, height: config.participantHeight)

            participantPositions.append(PositionedParticipant(
                participant: p,
                headerFrame: headerFrame,
                lifelineX: centerX,
                lifelineTop: lifelineTop,
                lifelineBottom: lifelineBottom
            ))
            participantXMap[p.id] = centerX
        }

        var messagePositions: [PositionedMessage] = []
        for (i, msg) in diagram.messages.enumerated() {
            let y = lifelineTop + CGFloat(i + 1) * config.messageSpacing
            let fromX = participantXMap[msg.from] ?? 0
            let toX = participantXMap[msg.to] ?? 0

            messagePositions.append(PositionedMessage(
                message: msg,
                fromX: fromX,
                toX: toX,
                y: y
            ))
        }

        let totalHeight = lifelineBottom + config.padding

        return SequenceLayout(
            participants: participantPositions,
            messages: messagePositions,
            size: CGSize(width: totalWidth, height: totalHeight)
        )
    }

    // MARK: - Pie Chart Layout

    struct PieLayout {
        let slices: [PositionedPieSlice]
        let center: CGPoint
        let radius: CGFloat
        let title: String?
        let titlePosition: CGPoint
        let size: CGSize
    }

    func layoutPieChart(_ diagram: PieChartDiagram) -> PieLayout {
        let total = diagram.slices.reduce(0) { $0 + $1.value }
        guard total > 0 else {
            return PieLayout(
                slices: [], center: .zero, radius: 0,
                title: diagram.title, titlePosition: .zero,
                size: CGSize(width: 100, height: 100)
            )
        }

        let legendWidth: CGFloat = 180
        let canvasWidth = config.padding * 2 + config.pieRadius * 2 + legendWidth
        let canvasHeight = config.padding * 2 + config.pieRadius * 2 + (diagram.title != nil ? 30 : 0)
        let titleY = config.padding + 10
        let centerY = (diagram.title != nil ? titleY + 30 : config.padding) + config.pieRadius
        let centerX = config.padding + config.pieRadius
        let center = CGPoint(x: centerX, y: centerY)

        var slices: [PositionedPieSlice] = []
        var currentAngle: CGFloat = -.pi / 2

        for (i, slice) in diagram.slices.enumerated() {
            let fraction = CGFloat(slice.value / total)
            let sliceAngle = fraction * 2 * .pi
            let endAngle = currentAngle + sliceAngle
            let midAngle = currentAngle + sliceAngle / 2

            let labelR = config.pieRadius + config.pieLabelOffset
            let labelPos = CGPoint(
                x: center.x + labelR * cos(midAngle),
                y: center.y + labelR * sin(midAngle)
            )

            slices.append(PositionedPieSlice(
                slice: slice,
                startAngle: currentAngle,
                endAngle: endAngle,
                color: config.pieColors[i % config.pieColors.count],
                labelPosition: labelPos,
                percentage: fraction * 100
            ))

            currentAngle = endAngle
        }

        return PieLayout(
            slices: slices,
            center: center,
            radius: config.pieRadius,
            title: diagram.title,
            titlePosition: CGPoint(x: centerX, y: titleY),
            size: CGSize(width: canvasWidth, height: canvasHeight)
        )
    }

    // MARK: - Class Diagram Layout

    struct ClassDiagramLayout {
        let classes: [PositionedClassBox]
        let relationships: [PositionedClassRelationship]
        let size: CGSize
    }

    func layoutClassDiagram(_ diagram: ClassDiagram) -> ClassDiagramLayout {
        var positioned: [String: PositionedClassBox] = [:]

        // Arrange classes in a grid
        let cols = max(1, Int(ceil(sqrt(Double(diagram.classes.count)))))

        for (i, cls) in diagram.classes.enumerated() {
            let col = i % cols
            let row = i / cols

            let propCount = max(cls.properties.count, 1)
            let methCount = max(cls.methods.count, 1)
            let totalHeight = config.classHeaderHeight +
                CGFloat(propCount) * config.classMemberHeight +
                CGFloat(methCount) * config.classMemberHeight + 4

            let x = config.padding + CGFloat(col) * (config.classBoxWidth + config.classSpacing)
            let y = config.padding + CGFloat(row) * (totalHeight + config.classSpacing)

            let frame = CGRect(x: x, y: y, width: config.classBoxWidth, height: totalHeight)
            let headerFrame = CGRect(x: x, y: y, width: config.classBoxWidth, height: config.classHeaderHeight)
            let propsY = y + config.classHeaderHeight
            let propsHeight = CGFloat(propCount) * config.classMemberHeight
            let propsFrame = CGRect(x: x, y: propsY, width: config.classBoxWidth, height: propsHeight)
            let methsY = propsY + propsHeight
            let methsHeight = CGFloat(methCount) * config.classMemberHeight
            let methsFrame = CGRect(x: x, y: methsY, width: config.classBoxWidth, height: methsHeight)

            positioned[cls.name] = PositionedClassBox(
                classDef: cls,
                frame: frame,
                headerFrame: headerFrame,
                propertiesFrame: propsFrame,
                methodsFrame: methsFrame
            )
        }

        // Position relationships
        let positionedRels = diagram.relationships.compactMap { rel -> PositionedClassRelationship? in
            guard let fromBox = positioned[rel.from],
                  let toBox = positioned[rel.to] else { return nil }

            let (fromPt, toPt) = connectBoxes(from: fromBox.frame, to: toBox.frame)

            let midX = (fromPt.x + toPt.x) / 2
            let midY = (fromPt.y + toPt.y) / 2

            let labelPos = rel.label != nil ? CGPoint(x: midX, y: midY - 10) : nil
            let fromLabelPos = rel.fromCardinality != nil ?
                CGPoint(x: fromPt.x + (toPt.x > fromPt.x ? 15 : -15), y: fromPt.y - 12) : nil
            let toLabelPos = rel.toCardinality != nil ?
                CGPoint(x: toPt.x + (fromPt.x > toPt.x ? 15 : -15), y: toPt.y - 12) : nil

            return PositionedClassRelationship(
                relationship: rel,
                fromPoint: fromPt, toPoint: toPt,
                fromLabelPos: fromLabelPos, toLabelPos: toLabelPos,
                labelPos: labelPos
            )
        }

        let allFrames = positioned.values.map(\.frame)
        let maxX = (allFrames.map { $0.maxX }.max() ?? 0) + config.padding
        let maxY = (allFrames.map { $0.maxY }.max() ?? 0) + config.padding

        return ClassDiagramLayout(
            classes: Array(positioned.values),
            relationships: positionedRels,
            size: CGSize(width: maxX, height: maxY)
        )
    }

    private func connectBoxes(from: CGRect, to: CGRect) -> (CGPoint, CGPoint) {
        // Find best connection points between two boxes
        let fromCenter = CGPoint(x: from.midX, y: from.midY)
        let toCenter = CGPoint(x: to.midX, y: to.midY)

        let dx = toCenter.x - fromCenter.x
        let dy = toCenter.y - fromCenter.y

        let fromPt: CGPoint
        let toPt: CGPoint

        if abs(dx) > abs(dy) {
            // Connect horizontally
            fromPt = CGPoint(x: dx > 0 ? from.maxX : from.minX, y: from.midY)
            toPt = CGPoint(x: dx > 0 ? to.minX : to.maxX, y: to.midY)
        } else {
            // Connect vertically
            fromPt = CGPoint(x: from.midX, y: dy > 0 ? from.maxY : from.minY)
            toPt = CGPoint(x: to.midX, y: dy > 0 ? to.minY : to.maxY)
        }

        return (fromPt, toPt)
    }

    // MARK: - State Diagram Layout

    struct StateDiagramLayout {
        let states: [PositionedState]
        let transitions: [PositionedStateTransition]
        let size: CGSize
    }

    func layoutStateDiagram(_ diagram: StateDiagram) -> StateDiagramLayout {
        // Build adjacency for topological layout
        let allIds = diagram.states.map(\.id)
        var inDegree: [String: Int] = Dictionary(uniqueKeysWithValues: allIds.map { ($0, 0) })
        var adjacency: [String: [String]] = [:]

        for t in diagram.transitions {
            adjacency[t.from, default: []].append(t.to)
            inDegree[t.to, default: 0] += 1
        }

        // Topological sort
        var queue = allIds.filter { (inDegree[$0] ?? 0) == 0 }.sorted()
        var sorted: [String] = []
        while !queue.isEmpty {
            let node = queue.removeFirst()
            sorted.append(node)
            for neighbor in adjacency[node, default: []] {
                inDegree[neighbor, default: 0] -= 1
                if inDegree[neighbor] == 0 {
                    queue.append(neighbor)
                }
            }
        }
        let remaining = Set(allIds).subtracting(sorted).sorted()
        sorted.append(contentsOf: remaining)

        // Assign layers
        var layerOf: [String: Int] = [:]
        for id in sorted {
            let incoming = diagram.transitions.filter { $0.to == id }.compactMap { layerOf[$0.from] }
            layerOf[id] = (incoming.max() ?? -1) + 1
        }

        let maxLayer = layerOf.values.max() ?? 0
        var layers: [[String]] = Array(repeating: [], count: maxLayer + 1)
        for (id, layer) in layerOf { layers[layer].append(id) }
        for i in layers.indices { layers[i].sort() }

        let stateMap = Dictionary(uniqueKeysWithValues: diagram.states.map { ($0.id, $0) })
        var positioned: [String: PositionedState] = [:]

        for (layerIndex, layer) in layers.enumerated() {
            for (nodeIndex, nodeId) in layer.enumerated() {
                guard let state = stateMap[nodeId] else { continue }
                let isStartEnd = nodeId == "[*]"
                let w = isStartEnd ? config.startEndRadius * 2 : config.stateWidth
                let h = isStartEnd ? config.startEndRadius * 2 : config.stateHeight

                let x = config.padding + CGFloat(nodeIndex) * (config.stateWidth + config.stateSpacing)
                let y = config.padding + CGFloat(layerIndex) * (config.stateHeight + config.stateSpacing)

                let frame = CGRect(x: x, y: y, width: w, height: h)
                positioned[nodeId] = PositionedState(state: state, frame: frame, isStartEnd: isStartEnd)
            }
        }

        let positionedTransitions = diagram.transitions.compactMap { t -> PositionedStateTransition? in
            guard let fromState = positioned[t.from],
                  let toState = positioned[t.to] else { return nil }

            let fromPt = CGPoint(x: fromState.frame.midX, y: fromState.frame.maxY)
            let toPt = CGPoint(x: toState.frame.midX, y: toState.frame.minY)

            let labelPos = t.label != nil ?
                CGPoint(x: (fromPt.x + toPt.x) / 2, y: (fromPt.y + toPt.y) / 2 - 10) : nil

            return PositionedStateTransition(
                transition: t,
                points: [fromPt, toPt],
                labelPosition: labelPos
            )
        }

        let allFrames = positioned.values.map(\.frame)
        let maxX = (allFrames.map { $0.maxX }.max() ?? 0) + config.padding
        let maxY = (allFrames.map { $0.maxY }.max() ?? 0) + config.padding

        return StateDiagramLayout(
            states: Array(positioned.values),
            transitions: positionedTransitions,
            size: CGSize(width: maxX, height: maxY)
        )
    }

    // MARK: - Gantt Chart Layout

    struct GanttLayout {
        let sections: [PositionedGanttSection]
        let tasks: [PositionedGanttTask]
        let title: String?
        let titlePosition: CGPoint
        let gridLines: [(CGFloat, String)]  // x position and label
        let size: CGSize
    }

    func layoutGanttChart(_ diagram: GanttDiagram) -> GanttLayout {
        let titleHeight: CGFloat = diagram.title != nil ? 35 : 0
        let headerHeight: CGFloat = 30
        var currentY = config.padding + titleHeight + headerHeight

        var positionedSections: [PositionedGanttSection] = []
        var positionedTasks: [PositionedGanttTask] = []

        // Count total tasks to determine width
        let allTasks = diagram.sections.flatMap(\.tasks)
        let totalDays = max(allTasks.count * 5, 20) // Estimate
        let chartWidth = config.ganttLabelWidth + CGFloat(totalDays) * config.ganttDayWidth

        var taskIndex = 0
        for (sectionIdx, section) in diagram.sections.enumerated() {
            positionedSections.append(PositionedGanttSection(name: section.name, y: currentY))
            currentY += config.ganttSectionSpacing

            for (_, task) in section.tasks.enumerated() {
                let barX = config.ganttLabelWidth + CGFloat(taskIndex * 3) * config.ganttDayWidth
                let barWidth = CGFloat(5) * config.ganttDayWidth  // Default 5-day duration
                let bar = CGRect(x: barX, y: currentY, width: barWidth, height: config.ganttBarHeight)

                let color: CGColor
                switch task.status {
                case .critical, .criticalActive:
                    color = config.ganttCriticalColor
                case .done, .criticalDone:
                    color = config.ganttDoneColor
                case .active:
                    color = config.ganttActiveColor
                case .normal:
                    color = config.ganttColors[sectionIdx % config.ganttColors.count]
                }

                let labelPos = CGPoint(x: config.padding + 10, y: currentY + config.ganttBarHeight / 2)
                positionedTasks.append(PositionedGanttTask(
                    task: task, bar: bar, labelPosition: labelPos, color: color
                ))

                currentY += config.ganttBarHeight + config.ganttBarSpacing
                taskIndex += 1
            }

            currentY += config.ganttSectionSpacing
        }

        let totalHeight = currentY + config.padding
        let totalWidth = max(chartWidth, 400) + config.padding

        // Grid lines
        var gridLines: [(CGFloat, String)] = []
        for i in 0..<(totalDays / 5 + 1) {
            let x = config.ganttLabelWidth + CGFloat(i * 5) * config.ganttDayWidth
            let label = "Day \(i * 5)"
            gridLines.append((x, label))
        }

        let titlePos = CGPoint(x: totalWidth / 2, y: config.padding + 15)

        return GanttLayout(
            sections: positionedSections,
            tasks: positionedTasks,
            title: diagram.title,
            titlePosition: titlePos,
            gridLines: gridLines,
            size: CGSize(width: totalWidth, height: totalHeight)
        )
    }

    // MARK: - ER Diagram Layout

    struct ERDiagramLayout {
        let entities: [PositionedEREntity]
        let relationships: [PositionedERRelationship]
        let size: CGSize
    }

    func layoutERDiagram(_ diagram: ERDiagram) -> ERDiagramLayout {
        var positioned: [String: PositionedEREntity] = [:]

        let cols = max(1, Int(ceil(sqrt(Double(diagram.entities.count)))))

        for (i, entity) in diagram.entities.enumerated() {
            let col = i % cols
            let row = i / cols

            let attrCount = max(entity.attributes.count, 1)
            let totalHeight = config.erEntityHeaderHeight + CGFloat(attrCount) * config.erAttributeHeight + 4

            let x = config.padding + CGFloat(col) * (config.erEntityWidth + config.erEntitySpacing)
            let y = config.padding + CGFloat(row) * (totalHeight + config.erEntitySpacing)

            let frame = CGRect(x: x, y: y, width: config.erEntityWidth, height: totalHeight)
            let headerFrame = CGRect(x: x, y: y, width: config.erEntityWidth, height: config.erEntityHeaderHeight)

            var attrFrames: [CGRect] = []
            for j in 0..<entity.attributes.count {
                let attrY = y + config.erEntityHeaderHeight + CGFloat(j) * config.erAttributeHeight
                attrFrames.append(CGRect(x: x, y: attrY, width: config.erEntityWidth, height: config.erAttributeHeight))
            }

            positioned[entity.name] = PositionedEREntity(
                entity: entity,
                frame: frame,
                headerFrame: headerFrame,
                attributeFrames: attrFrames
            )
        }

        let positionedRels = diagram.relationships.compactMap { rel -> PositionedERRelationship? in
            guard let fromEntity = positioned[rel.from],
                  let toEntity = positioned[rel.to] else { return nil }

            let (fromPt, toPt) = connectBoxes(from: fromEntity.frame, to: toEntity.frame)
            let labelPos = CGPoint(x: (fromPt.x + toPt.x) / 2, y: (fromPt.y + toPt.y) / 2 - 10)

            return PositionedERRelationship(
                relationship: rel,
                fromPoint: fromPt, toPoint: toPt,
                labelPosition: labelPos
            )
        }

        let allFrames = positioned.values.map(\.frame)
        let maxX = (allFrames.map { $0.maxX }.max() ?? 0) + config.padding
        let maxY = (allFrames.map { $0.maxY }.max() ?? 0) + config.padding

        return ERDiagramLayout(
            entities: Array(positioned.values),
            relationships: positionedRels,
            size: CGSize(width: maxX, height: maxY)
        )
    }
}
