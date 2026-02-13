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
        CGColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1), // blue
        CGColor(red: 0.92, green: 0.34, blue: 0.34, alpha: 1), // red
        CGColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1), // green
        CGColor(red: 1.00, green: 0.76, blue: 0.03, alpha: 1), // yellow
        CGColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1), // purple
        CGColor(red: 1.00, green: 0.60, blue: 0.00, alpha: 1), // orange
        CGColor(red: 0.00, green: 0.74, blue: 0.83, alpha: 1), // teal
        CGColor(red: 0.91, green: 0.47, blue: 0.62, alpha: 1), // pink
    ]

    public init() {}

    public static let `default` = LayoutConfig()
}

// MARK: - Layout Result Types

struct PositionedNode {
    let node: FlowNode
    let frame: CGRect
}

struct PositionedEdge {
    let edge: FlowEdge
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let labelPosition: CGPoint?
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
        let size: CGSize
    }

    func layoutFlowchart(_ diagram: FlowchartDiagram) -> FlowchartLayout {
        // Build adjacency and compute layers via topological sort
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
                positioned[nodeId] = PositionedNode(node: node, frame: frame)
            }
        }

        // Position edges
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

            let labelPos = edge.label != nil ?
                CGPoint(x: (fromPoint.x + toPoint.x) / 2, y: (fromPoint.y + toPoint.y) / 2 - 10) : nil

            return PositionedEdge(edge: edge, fromPoint: fromPoint, toPoint: toPoint, labelPosition: labelPos)
        }

        // Calculate total size
        let allFrames = positioned.values.map(\.frame)
        let maxX = (allFrames.map { $0.maxX }.max() ?? 0) + config.padding
        let maxY = (allFrames.map { $0.maxY }.max() ?? 0) + config.padding

        return FlowchartLayout(
            nodes: Array(positioned.values),
            edges: positionedEdges,
            size: CGSize(width: maxX, height: maxY)
        )
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

        // Add any remaining nodes (cycles)
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

        // Sort within layers for stability
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

        // Position participants
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

        // Position messages
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
        var currentAngle: CGFloat = -.pi / 2 // Start at top

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
}
