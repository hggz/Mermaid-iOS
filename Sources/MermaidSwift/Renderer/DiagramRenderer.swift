import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Renders laid-out diagrams to CGImage using CoreGraphics.
struct DiagramRenderer {

    let config: LayoutConfig

    init(config: LayoutConfig = .default) {
        self.config = config
    }

    // MARK: - Public API

    func renderFlowchart(_ layout: DiagramLayout.FlowchartLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        // Draw subgraphs (behind everything)
        for sg in layout.subgraphs {
            drawSubgraph(ctx, subgraph: sg)
        }

        // Draw edges
        for edge in layout.edges {
            drawEdge(ctx, edge: edge)
        }

        // Draw nodes
        for node in layout.nodes {
            drawFlowNode(ctx, node: node)
        }

        return ctx.makeImage()
    }

    func renderSequenceDiagram(_ layout: DiagramLayout.SequenceLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        for p in layout.participants {
            drawLifeline(ctx, participant: p)
        }
        for p in layout.participants {
            drawParticipantBox(ctx, participant: p)
        }
        for msg in layout.messages {
            drawMessage(ctx, message: msg)
        }

        return ctx.makeImage()
    }

    func renderPieChart(_ layout: DiagramLayout.PieLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        if let title = layout.title {
            drawText(ctx, text: title, at: layout.titlePosition,
                     fontSize: config.titleFontSize, bold: true, alignment: .center)
        }

        for slice in layout.slices {
            drawPieSlice(ctx, slice: slice, center: layout.center, radius: layout.radius)
        }

        drawPieLegend(ctx, slices: layout.slices, center: layout.center, radius: layout.radius)

        return ctx.makeImage()
    }

    func renderClassDiagram(_ layout: DiagramLayout.ClassDiagramLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        // Draw relationships first (behind boxes)
        for rel in layout.relationships {
            drawClassRelationship(ctx, rel: rel)
        }

        // Draw class boxes
        for cls in layout.classes {
            drawClassBox(ctx, classBox: cls)
        }

        return ctx.makeImage()
    }

    func renderStateDiagram(_ layout: DiagramLayout.StateDiagramLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        for t in layout.transitions {
            drawStateTransition(ctx, transition: t)
        }
        for s in layout.states {
            drawState(ctx, state: s)
        }

        return ctx.makeImage()
    }

    func renderGanttChart(_ layout: DiagramLayout.GanttLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        // Title
        if let title = layout.title {
            drawText(ctx, text: title, at: layout.titlePosition,
                     fontSize: config.titleFontSize, bold: true, alignment: .center)
        }

        // Grid lines
        for (x, label) in layout.gridLines {
            ctx.saveGState()
            ctx.setStrokeColor(CGColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1))
            ctx.setLineWidth(0.5)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: config.padding + 35))
            ctx.addLine(to: CGPoint(x: x, y: size.height - config.padding))
            ctx.strokePath()
            ctx.restoreGState()

            drawText(ctx, text: label,
                     at: CGPoint(x: x, y: config.padding + 45),
                     fontSize: config.fontSize - 3, bold: false, alignment: .center)
        }

        // Section labels
        for section in layout.sections {
            drawText(ctx, text: section.name,
                     at: CGPoint(x: config.padding + 10, y: section.y + 6),
                     fontSize: config.fontSize - 1, bold: true, alignment: .left)
        }

        // Task bars
        for task in layout.tasks {
            drawGanttTask(ctx, task: task)
        }

        return ctx.makeImage()
    }

    func renderERDiagram(_ layout: DiagramLayout.ERDiagramLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        for rel in layout.relationships {
            drawERRelationship(ctx, rel: rel)
        }
        for entity in layout.entities {
            drawEREntity(ctx, entity: entity)
        }

        return ctx.makeImage()
    }

    // MARK: - Context Creation

    private func createContext(size: CGSize) -> CGContext? {
        let scale: CGFloat = 2.0
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: 0, y: size.height)
        ctx.scaleBy(x: 1, y: -1)

        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.setShouldSmoothFonts(true)

        return ctx
    }

    private func fillBackground(_ ctx: CGContext, size: CGSize) {
        ctx.setFillColor(config.backgroundColor)
        ctx.fill(CGRect(origin: .zero, size: size))
    }

    // MARK: - Color Parsing

    private func parseCSSColor(_ css: String) -> CGColor? {
        let hex = css.trimmingCharacters(in: .whitespaces)
        guard hex.hasPrefix("#") else { return nil }

        let hexStr = String(hex.dropFirst())
        var value: UInt64 = 0
        Scanner(string: hexStr).scanHexInt64(&value)

        if hexStr.count == 3 {
            let r = CGFloat((value >> 8) & 0xF) / 15.0
            let g = CGFloat((value >> 4) & 0xF) / 15.0
            let b = CGFloat(value & 0xF) / 15.0
            return CGColor(red: r, green: g, blue: b, alpha: 1)
        } else if hexStr.count == 6 {
            let r = CGFloat((value >> 16) & 0xFF) / 255.0
            let g = CGFloat((value >> 8) & 0xFF) / 255.0
            let b = CGFloat(value & 0xFF) / 255.0
            return CGColor(red: r, green: g, blue: b, alpha: 1)
        }

        return nil
    }

    // MARK: - Subgraph Drawing

    private func drawSubgraph(_ ctx: CGContext, subgraph: PositionedSubgraph) {
        let frame = subgraph.frame

        ctx.saveGState()
        ctx.setFillColor(config.subgraphFillColor)
        ctx.setStrokeColor(config.subgraphBorderColor)
        ctx.setLineWidth(1.5)
        ctx.setLineDash(phase: 0, lengths: [6, 3])

        let path = CGPath(roundedRect: frame, cornerWidth: 8, cornerHeight: 8, transform: nil)
        ctx.addPath(path)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()

        // Label
        drawText(ctx, text: subgraph.subgraph.label,
                 at: subgraph.labelPosition,
                 fontSize: config.fontSize - 1, bold: true, alignment: .left)
    }

    // MARK: - Flowchart Drawing

    private func drawFlowNode(_ ctx: CGContext, node: PositionedNode) {
        let frame = node.frame

        ctx.saveGState()

        // Apply custom style if present
        let fillColor = node.style?.fill.flatMap(parseCSSColor) ?? config.nodeColor
        let strokeColor = node.style?.stroke.flatMap(parseCSSColor) ?? config.nodeBorderColor
        let strokeWidth = node.style?.strokeWidth ?? config.lineWidth
        let textColor = node.style?.color.flatMap(parseCSSColor) ?? config.textColor

        ctx.setFillColor(fillColor)
        ctx.setStrokeColor(strokeColor)
        ctx.setLineWidth(strokeWidth)

        switch node.node.shape {
        case .rectangle:
            ctx.addRect(frame)
            ctx.drawPath(using: .fillStroke)

        case .roundedRect:
            let path = CGPath(roundedRect: frame, cornerWidth: config.nodeCornerRadius,
                              cornerHeight: config.nodeCornerRadius, transform: nil)
            ctx.addPath(path)
            ctx.drawPath(using: .fillStroke)

        case .stadium:
            let radius = frame.height / 2
            let path = CGPath(roundedRect: frame, cornerWidth: radius,
                              cornerHeight: radius, transform: nil)
            ctx.addPath(path)
            ctx.drawPath(using: .fillStroke)

        case .diamond:
            ctx.beginPath()
            ctx.move(to: CGPoint(x: frame.midX, y: frame.minY))
            ctx.addLine(to: CGPoint(x: frame.maxX, y: frame.midY))
            ctx.addLine(to: CGPoint(x: frame.midX, y: frame.maxY))
            ctx.addLine(to: CGPoint(x: frame.minX, y: frame.midY))
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)

        case .hexagon:
            let inset: CGFloat = 15
            ctx.beginPath()
            ctx.move(to: CGPoint(x: frame.minX + inset, y: frame.minY))
            ctx.addLine(to: CGPoint(x: frame.maxX - inset, y: frame.minY))
            ctx.addLine(to: CGPoint(x: frame.maxX, y: frame.midY))
            ctx.addLine(to: CGPoint(x: frame.maxX - inset, y: frame.maxY))
            ctx.addLine(to: CGPoint(x: frame.minX + inset, y: frame.maxY))
            ctx.addLine(to: CGPoint(x: frame.minX, y: frame.midY))
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)

        case .circle:
            let diameter = min(frame.width, frame.height)
            let circleRect = CGRect(
                x: frame.midX - diameter / 2,
                y: frame.midY - diameter / 2,
                width: diameter,
                height: diameter
            )
            ctx.addEllipse(in: circleRect)
            ctx.drawPath(using: .fillStroke)

        case .asymmetric:
            let inset: CGFloat = 15
            ctx.beginPath()
            ctx.move(to: CGPoint(x: frame.minX + inset, y: frame.minY))
            ctx.addLine(to: CGPoint(x: frame.maxX, y: frame.minY))
            ctx.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))
            ctx.addLine(to: CGPoint(x: frame.minX + inset, y: frame.maxY))
            ctx.addLine(to: CGPoint(x: frame.minX, y: frame.midY))
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)
        }

        ctx.restoreGState()

        drawText(ctx, text: node.node.label,
                 at: CGPoint(x: frame.midX, y: frame.midY),
                 fontSize: config.fontSize, bold: false, alignment: .center,
                 color: textColor)
    }

    private func drawEdge(_ ctx: CGContext, edge: PositionedEdge) {
        ctx.saveGState()
        ctx.setStrokeColor(config.edgeColor)
        ctx.setLineWidth(config.lineWidth)

        switch edge.edge.style {
        case .solid:
            ctx.setLineDash(phase: 0, lengths: [])
        case .dotted:
            ctx.setLineDash(phase: 0, lengths: [6, 4])
        case .thick:
            ctx.setLineWidth(config.lineWidth * 2)
            ctx.setLineDash(phase: 0, lengths: [])
        case .invisible:
            ctx.restoreGState()
            return
        }

        // Draw multi-point path
        guard let first = edge.points.first else {
            ctx.restoreGState()
            return
        }

        ctx.beginPath()
        ctx.move(to: first)
        for point in edge.points.dropFirst() {
            ctx.addLine(to: point)
        }
        ctx.strokePath()

        // Draw arrowhead at the last segment
        if edge.points.count >= 2 {
            let from = edge.points[edge.points.count - 2]
            let to = edge.points[edge.points.count - 1]
            drawArrowhead(ctx, from: from, to: to)
        }

        ctx.restoreGState()

        // Edge label
        if let label = edge.edge.label, let pos = edge.labelPosition {
            let labelSize = measureText(label, fontSize: config.fontSize - 2)
            let bgRect = CGRect(
                x: pos.x - labelSize.width / 2 - 4,
                y: pos.y - labelSize.height / 2 - 2,
                width: labelSize.width + 8,
                height: labelSize.height + 4
            )
            ctx.saveGState()
            ctx.setFillColor(config.backgroundColor)
            ctx.fill(bgRect)
            ctx.restoreGState()

            drawText(ctx, text: label, at: pos, fontSize: config.fontSize - 2,
                     bold: false, alignment: .center)
        }
    }

    private func drawArrowhead(_ ctx: CGContext, from: CGPoint, to: CGPoint) {
        let arrowLength: CGFloat = 10
        let arrowWidth: CGFloat = 6
        let angle = atan2(to.y - from.y, to.x - from.x)

        ctx.saveGState()
        ctx.setFillColor(config.arrowColor)

        let p1 = CGPoint(
            x: to.x - arrowLength * cos(angle) + arrowWidth * sin(angle),
            y: to.y - arrowLength * sin(angle) - arrowWidth * cos(angle)
        )
        let p2 = CGPoint(
            x: to.x - arrowLength * cos(angle) - arrowWidth * sin(angle),
            y: to.y - arrowLength * sin(angle) + arrowWidth * cos(angle)
        )

        ctx.beginPath()
        ctx.move(to: to)
        ctx.addLine(to: p1)
        ctx.addLine(to: p2)
        ctx.closePath()
        ctx.fillPath()
        ctx.restoreGState()
    }

    // MARK: - Sequence Diagram Drawing

    private func drawLifeline(_ ctx: CGContext, participant: PositionedParticipant) {
        ctx.saveGState()
        ctx.setStrokeColor(config.lifelineColor)
        ctx.setLineWidth(1)
        ctx.setLineDash(phase: 0, lengths: [6, 4])
        ctx.beginPath()
        ctx.move(to: CGPoint(x: participant.lifelineX, y: participant.lifelineTop))
        ctx.addLine(to: CGPoint(x: participant.lifelineX, y: participant.lifelineBottom))
        ctx.strokePath()
        ctx.restoreGState()
    }

    private func drawParticipantBox(_ ctx: CGContext, participant: PositionedParticipant) {
        let frame = participant.headerFrame

        ctx.saveGState()
        ctx.setFillColor(config.nodeColor)
        ctx.setStrokeColor(config.nodeBorderColor)
        ctx.setLineWidth(config.lineWidth)
        let path = CGPath(roundedRect: frame, cornerWidth: 6, cornerHeight: 6, transform: nil)
        ctx.addPath(path)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()

        drawText(ctx, text: participant.participant.label,
                 at: CGPoint(x: frame.midX, y: frame.midY),
                 fontSize: config.fontSize, bold: true, alignment: .center)
    }

    private func drawMessage(_ ctx: CGContext, message: PositionedMessage) {
        ctx.saveGState()
        ctx.setStrokeColor(config.edgeColor)
        ctx.setLineWidth(config.lineWidth)

        switch message.message.style {
        case .dottedArrow, .dottedLine, .dottedCross:
            ctx.setLineDash(phase: 0, lengths: [6, 4])
        default:
            ctx.setLineDash(phase: 0, lengths: [])
        }

        let fromPt = CGPoint(x: message.fromX, y: message.y)
        let toPt = CGPoint(x: message.toX, y: message.y)

        ctx.beginPath()
        ctx.move(to: fromPt)
        ctx.addLine(to: toPt)
        ctx.strokePath()

        switch message.message.style {
        case .solidArrow, .dottedArrow:
            drawArrowhead(ctx, from: fromPt, to: toPt)
        case .solidCross, .dottedCross:
            drawCross(ctx, at: toPt)
        default:
            drawArrowhead(ctx, from: fromPt, to: toPt)
        }

        ctx.restoreGState()

        let labelX = (message.fromX + message.toX) / 2
        let labelY = message.y - 8
        drawText(ctx, text: message.message.text,
                 at: CGPoint(x: labelX, y: labelY),
                 fontSize: config.fontSize - 1, bold: false, alignment: .center)
    }

    private func drawCross(_ ctx: CGContext, at point: CGPoint) {
        let size: CGFloat = 6
        ctx.saveGState()
        ctx.setStrokeColor(config.arrowColor)
        ctx.setLineWidth(config.lineWidth)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: point.x - size, y: point.y - size))
        ctx.addLine(to: CGPoint(x: point.x + size, y: point.y + size))
        ctx.move(to: CGPoint(x: point.x + size, y: point.y - size))
        ctx.addLine(to: CGPoint(x: point.x - size, y: point.y + size))
        ctx.strokePath()
        ctx.restoreGState()
    }

    // MARK: - Pie Chart Drawing

    private func drawPieSlice(_ ctx: CGContext, slice: PositionedPieSlice,
                              center: CGPoint, radius: CGFloat) {
        ctx.saveGState()
        ctx.setFillColor(slice.color)
        ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.setLineWidth(2)

        ctx.beginPath()
        ctx.move(to: center)
        ctx.addArc(center: center, radius: radius,
                   startAngle: slice.startAngle, endAngle: slice.endAngle, clockwise: false)
        ctx.closePath()
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()
    }

    private func drawPieLegend(_ ctx: CGContext, slices: [PositionedPieSlice],
                               center: CGPoint, radius: CGFloat) {
        let legendX = center.x + radius + 40
        var legendY = center.y - CGFloat(slices.count) * 12

        for slice in slices {
            let swatchRect = CGRect(x: legendX, y: legendY - 6, width: 12, height: 12)
            ctx.saveGState()
            ctx.setFillColor(slice.color)
            ctx.fill(swatchRect)
            ctx.restoreGState()

            let text = String(format: "%@ (%.1f%%)", slice.slice.label, slice.percentage)
            drawText(ctx, text: text,
                     at: CGPoint(x: legendX + 20, y: legendY),
                     fontSize: config.fontSize - 2, bold: false, alignment: .left)

            legendY += 24
        }
    }

    // MARK: - Class Diagram Drawing

    private func drawClassBox(_ ctx: CGContext, classBox: PositionedClassBox) {
        let cls = classBox.classDef

        // Full box background + border
        ctx.saveGState()
        ctx.setFillColor(config.backgroundColor)
        ctx.setStrokeColor(config.nodeBorderColor)
        ctx.setLineWidth(config.lineWidth)
        ctx.addRect(classBox.frame)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()

        // Header background
        ctx.saveGState()
        ctx.setFillColor(config.nodeColor)
        ctx.addRect(classBox.headerFrame)
        ctx.fillPath()
        ctx.restoreGState()

        // Header text
        var headerY = classBox.headerFrame.midY
        if let annotation = cls.annotation {
            headerY -= 6
            drawText(ctx, text: "<<\(annotation)>>",
                     at: CGPoint(x: classBox.headerFrame.midX, y: headerY - 2),
                     fontSize: config.fontSize - 3, bold: false, alignment: .center)
            headerY += 12
        }
        drawText(ctx, text: cls.name,
                 at: CGPoint(x: classBox.headerFrame.midX, y: headerY),
                 fontSize: config.fontSize, bold: true, alignment: .center)

        // Separator line under header
        ctx.saveGState()
        ctx.setStrokeColor(config.nodeBorderColor)
        ctx.setLineWidth(1)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: classBox.frame.minX, y: classBox.headerFrame.maxY))
        ctx.addLine(to: CGPoint(x: classBox.frame.maxX, y: classBox.headerFrame.maxY))
        ctx.strokePath()
        ctx.restoreGState()

        // Properties
        let propStartY = classBox.propertiesFrame.minY + 4
        for (i, prop) in cls.properties.enumerated() {
            let y = propStartY + CGFloat(i) * config.classMemberHeight + config.classMemberHeight / 2
            let text = "\(prop.visibility.rawValue)\(prop.memberType != nil ? "\(prop.memberType!) " : "")\(prop.name)"
            drawText(ctx, text: text,
                     at: CGPoint(x: classBox.frame.minX + 10, y: y),
                     fontSize: config.fontSize - 2, bold: false, alignment: .left)
        }

        // Separator line between properties and methods
        if !cls.properties.isEmpty || !cls.methods.isEmpty {
            ctx.saveGState()
            ctx.setStrokeColor(config.nodeBorderColor)
            ctx.setLineWidth(0.5)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: classBox.frame.minX, y: classBox.methodsFrame.minY))
            ctx.addLine(to: CGPoint(x: classBox.frame.maxX, y: classBox.methodsFrame.minY))
            ctx.strokePath()
            ctx.restoreGState()
        }

        // Methods
        let methStartY = classBox.methodsFrame.minY + 4
        for (i, meth) in cls.methods.enumerated() {
            let y = methStartY + CGFloat(i) * config.classMemberHeight + config.classMemberHeight / 2
            let returnType = meth.memberType != nil ? " \(meth.memberType!)" : ""
            let text = "\(meth.visibility.rawValue)\(meth.name)\(returnType)"
            drawText(ctx, text: text,
                     at: CGPoint(x: classBox.frame.minX + 10, y: y),
                     fontSize: config.fontSize - 2, bold: false, alignment: .left)
        }
    }

    private func drawClassRelationship(_ ctx: CGContext, rel: PositionedClassRelationship) {
        ctx.saveGState()
        ctx.setStrokeColor(config.edgeColor)
        ctx.setLineWidth(config.lineWidth)

        // Line style based on relationship type
        switch rel.relationship.relationshipType {
        case .dependency, .realization:
            ctx.setLineDash(phase: 0, lengths: [6, 4])
        default:
            ctx.setLineDash(phase: 0, lengths: [])
        }

        ctx.beginPath()
        ctx.move(to: rel.fromPoint)
        ctx.addLine(to: rel.toPoint)
        ctx.strokePath()

        // Draw relationship markers
        drawRelationshipMarker(ctx, type: rel.relationship.relationshipType,
                               from: rel.fromPoint, to: rel.toPoint)

        ctx.restoreGState()

        // Labels
        if let label = rel.relationship.label, let pos = rel.labelPos {
            drawText(ctx, text: label, at: pos,
                     fontSize: config.fontSize - 2, bold: false, alignment: .center)
        }
        if let card = rel.relationship.fromCardinality, let pos = rel.fromLabelPos {
            drawText(ctx, text: card, at: pos,
                     fontSize: config.fontSize - 3, bold: false, alignment: .center)
        }
        if let card = rel.relationship.toCardinality, let pos = rel.toLabelPos {
            drawText(ctx, text: card, at: pos,
                     fontSize: config.fontSize - 3, bold: false, alignment: .center)
        }
    }

    private func drawRelationshipMarker(_ ctx: CGContext, type: ClassRelationship.ClassRelationType,
                                        from: CGPoint, to: CGPoint) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let size: CGFloat = 12

        switch type {
        case .inheritance, .realization:
            // Open triangle arrowhead at target
            drawTriangleArrow(ctx, at: to, angle: angle, size: size, filled: false)

        case .composition:
            // Filled diamond at source
            drawDiamond(ctx, at: from, angle: angle + .pi, size: size, filled: true)

        case .aggregation:
            // Open diamond at source
            drawDiamond(ctx, at: from, angle: angle + .pi, size: size, filled: false)

        case .association:
            drawArrowhead(ctx, from: from, to: to)

        case .dependency:
            drawArrowhead(ctx, from: from, to: to)
        }
    }

    private func drawTriangleArrow(_ ctx: CGContext, at point: CGPoint, angle: CGFloat,
                                   size: CGFloat, filled: Bool) {
        let halfWidth: CGFloat = size / 2.5

        let p1 = CGPoint(
            x: point.x - size * cos(angle) + halfWidth * sin(angle),
            y: point.y - size * sin(angle) - halfWidth * cos(angle)
        )
        let p2 = CGPoint(
            x: point.x - size * cos(angle) - halfWidth * sin(angle),
            y: point.y - size * sin(angle) + halfWidth * cos(angle)
        )

        ctx.saveGState()
        ctx.beginPath()
        ctx.move(to: point)
        ctx.addLine(to: p1)
        ctx.addLine(to: p2)
        ctx.closePath()

        if filled {
            ctx.setFillColor(config.edgeColor)
            ctx.fillPath()
        } else {
            ctx.setFillColor(config.backgroundColor)
            ctx.drawPath(using: .fillStroke)
        }
        ctx.restoreGState()
    }

    private func drawDiamond(_ ctx: CGContext, at point: CGPoint, angle: CGFloat,
                             size: CGFloat, filled: Bool) {
        let halfWidth: CGFloat = size / 3

        let tip = point
        let left = CGPoint(
            x: tip.x + (size / 2) * cos(angle) + halfWidth * sin(angle),
            y: tip.y + (size / 2) * sin(angle) - halfWidth * cos(angle)
        )
        let back = CGPoint(
            x: tip.x + size * cos(angle),
            y: tip.y + size * sin(angle)
        )
        let right = CGPoint(
            x: tip.x + (size / 2) * cos(angle) - halfWidth * sin(angle),
            y: tip.y + (size / 2) * sin(angle) + halfWidth * cos(angle)
        )

        ctx.saveGState()
        ctx.beginPath()
        ctx.move(to: tip)
        ctx.addLine(to: left)
        ctx.addLine(to: back)
        ctx.addLine(to: right)
        ctx.closePath()

        if filled {
            ctx.setFillColor(config.edgeColor)
            ctx.fillPath()
        } else {
            ctx.setFillColor(config.backgroundColor)
            ctx.drawPath(using: .fillStroke)
        }
        ctx.restoreGState()
    }

    // MARK: - State Diagram Drawing

    private func drawState(_ ctx: CGContext, state: PositionedState) {
        let frame = state.frame

        if state.isStartEnd {
            // Start/end marker: filled circle
            ctx.saveGState()
            ctx.setFillColor(config.edgeColor)
            ctx.addEllipse(in: frame)
            ctx.fillPath()
            ctx.restoreGState()

            // If it's an end state (has incoming transitions to [*]), add inner circle
            // We'll just draw all [*] as filled circles. The distinction between
            // start and end is positional in the diagram.
            return
        }

        // Regular state: rounded rectangle
        ctx.saveGState()
        ctx.setFillColor(config.nodeColor)
        ctx.setStrokeColor(config.nodeBorderColor)
        ctx.setLineWidth(config.lineWidth)

        let path = CGPath(roundedRect: frame, cornerWidth: config.stateCornerRadius,
                          cornerHeight: config.stateCornerRadius, transform: nil)
        ctx.addPath(path)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()

        // State label
        var labelY = frame.midY
        if let desc = state.state.description {
            labelY -= 8
            drawText(ctx, text: state.state.label,
                     at: CGPoint(x: frame.midX, y: labelY),
                     fontSize: config.fontSize, bold: true, alignment: .center)
            drawText(ctx, text: desc,
                     at: CGPoint(x: frame.midX, y: labelY + 16),
                     fontSize: config.fontSize - 2, bold: false, alignment: .center)
        } else {
            drawText(ctx, text: state.state.label,
                     at: CGPoint(x: frame.midX, y: labelY),
                     fontSize: config.fontSize, bold: false, alignment: .center)
        }
    }

    private func drawStateTransition(_ ctx: CGContext, transition: PositionedStateTransition) {
        guard let first = transition.points.first else { return }

        ctx.saveGState()
        ctx.setStrokeColor(config.edgeColor)
        ctx.setLineWidth(config.lineWidth)

        ctx.beginPath()
        ctx.move(to: first)
        for pt in transition.points.dropFirst() {
            ctx.addLine(to: pt)
        }
        ctx.strokePath()

        if transition.points.count >= 2 {
            let from = transition.points[transition.points.count - 2]
            let to = transition.points[transition.points.count - 1]
            drawArrowhead(ctx, from: from, to: to)
        }

        ctx.restoreGState()

        // Label
        if let label = transition.transition.label, let pos = transition.labelPosition {
            let labelSize = measureText(label, fontSize: config.fontSize - 2)
            let bgRect = CGRect(
                x: pos.x - labelSize.width / 2 - 4,
                y: pos.y - labelSize.height / 2 - 2,
                width: labelSize.width + 8,
                height: labelSize.height + 4
            )
            ctx.saveGState()
            ctx.setFillColor(config.backgroundColor)
            ctx.fill(bgRect)
            ctx.restoreGState()

            drawText(ctx, text: label, at: pos,
                     fontSize: config.fontSize - 2, bold: false, alignment: .center)
        }
    }

    // MARK: - Gantt Chart Drawing

    private func drawGanttTask(_ ctx: CGContext, task: PositionedGanttTask) {
        let bar = task.bar

        ctx.saveGState()
        ctx.setFillColor(task.color)

        // Rounded bar
        let path = CGPath(roundedRect: bar, cornerWidth: 4, cornerHeight: 4, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()

        // Border for active/critical tasks
        if task.task.status == .active || task.task.status == .critical ||
           task.task.status == .criticalActive {
            ctx.setStrokeColor(config.edgeColor)
            ctx.setLineWidth(1.5)
            ctx.addPath(path)
            ctx.strokePath()
        }

        // Stripe pattern for done tasks
        if task.task.status == .done || task.task.status == .criticalDone {
            ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.3))
            ctx.setLineWidth(1)
            var x = bar.minX + 4
            while x < bar.maxX {
                ctx.beginPath()
                ctx.move(to: CGPoint(x: x, y: bar.minY))
                ctx.addLine(to: CGPoint(x: x - 8, y: bar.maxY))
                ctx.strokePath()
                x += 6
            }
        }

        ctx.restoreGState()

        // Task name label
        drawText(ctx, text: task.task.name,
                 at: task.labelPosition,
                 fontSize: config.fontSize - 2, bold: false, alignment: .left)

        // Task name on bar
        drawText(ctx, text: task.task.name,
                 at: CGPoint(x: bar.midX, y: bar.midY),
                 fontSize: config.fontSize - 3, bold: false, alignment: .center,
                 color: CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    }

    // MARK: - ER Diagram Drawing

    private func drawEREntity(_ ctx: CGContext, entity: PositionedEREntity) {
        // Full box
        ctx.saveGState()
        ctx.setFillColor(config.backgroundColor)
        ctx.setStrokeColor(config.nodeBorderColor)
        ctx.setLineWidth(config.lineWidth)
        ctx.addRect(entity.frame)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()

        // Header
        ctx.saveGState()
        ctx.setFillColor(config.nodeColor)
        ctx.addRect(entity.headerFrame)
        ctx.fillPath()
        ctx.restoreGState()

        drawText(ctx, text: entity.entity.name,
                 at: CGPoint(x: entity.headerFrame.midX, y: entity.headerFrame.midY),
                 fontSize: config.fontSize, bold: true, alignment: .center)

        // Separator
        ctx.saveGState()
        ctx.setStrokeColor(config.nodeBorderColor)
        ctx.setLineWidth(1)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: entity.frame.minX, y: entity.headerFrame.maxY))
        ctx.addLine(to: CGPoint(x: entity.frame.maxX, y: entity.headerFrame.maxY))
        ctx.strokePath()
        ctx.restoreGState()

        // Attributes
        for (i, attr) in entity.entity.attributes.enumerated() {
            guard i < entity.attributeFrames.count else { break }
            let attrFrame = entity.attributeFrames[i]
            let keyStr = attr.key != nil ? " \(attr.key!.rawValue)" : ""
            let text = "\(attr.attributeType) \(attr.name)\(keyStr)"
            drawText(ctx, text: text,
                     at: CGPoint(x: entity.frame.minX + 10, y: attrFrame.midY),
                     fontSize: config.fontSize - 2, bold: attr.key != nil, alignment: .left)
        }
    }

    private func drawERRelationship(_ ctx: CGContext, rel: PositionedERRelationship) {
        ctx.saveGState()
        ctx.setStrokeColor(config.edgeColor)
        ctx.setLineWidth(config.lineWidth)

        ctx.beginPath()
        ctx.move(to: rel.fromPoint)
        ctx.addLine(to: rel.toPoint)
        ctx.strokePath()

        // Draw cardinality markers
        let angle = atan2(rel.toPoint.y - rel.fromPoint.y, rel.toPoint.x - rel.fromPoint.x)
        drawERCardinality(ctx, cardinality: rel.relationship.fromCardinality,
                          at: rel.fromPoint, angle: angle)
        drawERCardinality(ctx, cardinality: rel.relationship.toCardinality,
                          at: rel.toPoint, angle: angle + .pi)

        ctx.restoreGState()

        // Label
        if !rel.relationship.label.isEmpty {
            let labelSize = measureText(rel.relationship.label, fontSize: config.fontSize - 2)
            let bgRect = CGRect(
                x: rel.labelPosition.x - labelSize.width / 2 - 4,
                y: rel.labelPosition.y - labelSize.height / 2 - 2,
                width: labelSize.width + 8,
                height: labelSize.height + 4
            )
            ctx.saveGState()
            ctx.setFillColor(config.backgroundColor)
            ctx.fill(bgRect)
            ctx.restoreGState()

            drawText(ctx, text: rel.relationship.label, at: rel.labelPosition,
                     fontSize: config.fontSize - 2, bold: false, alignment: .center)
        }
    }

    private func drawERCardinality(_ ctx: CGContext, cardinality: ERRelationship.ERCardinality,
                                   at point: CGPoint, angle: CGFloat) {
        let offset: CGFloat = 15
        let markerPoint = CGPoint(
            x: point.x + offset * cos(angle),
            y: point.y + offset * sin(angle)
        )

        let perpAngle = angle + .pi / 2
        let lineLen: CGFloat = 8

        ctx.saveGState()
        ctx.setStrokeColor(config.edgeColor)
        ctx.setLineWidth(1.5)

        switch cardinality {
        case .exactlyOne:
            // Two vertical lines ||
            for d: CGFloat in [-3, 3] {
                let p = CGPoint(x: markerPoint.x + d * cos(angle), y: markerPoint.y + d * sin(angle))
                ctx.beginPath()
                ctx.move(to: CGPoint(x: p.x - lineLen/2 * cos(perpAngle), y: p.y - lineLen/2 * sin(perpAngle)))
                ctx.addLine(to: CGPoint(x: p.x + lineLen/2 * cos(perpAngle), y: p.y + lineLen/2 * sin(perpAngle)))
                ctx.strokePath()
            }

        case .zeroOrOne:
            // Line and circle |o
            ctx.beginPath()
            ctx.move(to: CGPoint(x: markerPoint.x - lineLen/2 * cos(perpAngle), y: markerPoint.y - lineLen/2 * sin(perpAngle)))
            ctx.addLine(to: CGPoint(x: markerPoint.x + lineLen/2 * cos(perpAngle), y: markerPoint.y + lineLen/2 * sin(perpAngle)))
            ctx.strokePath()

            let circleCenter = CGPoint(x: markerPoint.x + 8 * cos(angle), y: markerPoint.y + 8 * sin(angle))
            ctx.addEllipse(in: CGRect(x: circleCenter.x - 4, y: circleCenter.y - 4, width: 8, height: 8))
            ctx.strokePath()

        case .zeroOrMore:
            // Circle and crow's foot o{
            let circleCenter = CGPoint(x: markerPoint.x - 4 * cos(angle), y: markerPoint.y - 4 * sin(angle))
            ctx.addEllipse(in: CGRect(x: circleCenter.x - 4, y: circleCenter.y - 4, width: 8, height: 8))
            ctx.strokePath()

            drawCrowsFoot(ctx, at: CGPoint(x: markerPoint.x + 6 * cos(angle), y: markerPoint.y + 6 * sin(angle)),
                          angle: angle, size: lineLen)

        case .oneOrMore:
            // Line and crow's foot }|
            ctx.beginPath()
            ctx.move(to: CGPoint(x: markerPoint.x - lineLen/2 * cos(perpAngle), y: markerPoint.y - lineLen/2 * sin(perpAngle)))
            ctx.addLine(to: CGPoint(x: markerPoint.x + lineLen/2 * cos(perpAngle), y: markerPoint.y + lineLen/2 * sin(perpAngle)))
            ctx.strokePath()

            drawCrowsFoot(ctx, at: CGPoint(x: markerPoint.x + 8 * cos(angle), y: markerPoint.y + 8 * sin(angle)),
                          angle: angle, size: lineLen)
        }

        ctx.restoreGState()
    }

    private func drawCrowsFoot(_ ctx: CGContext, at point: CGPoint, angle: CGFloat, size: CGFloat) {
        let perpAngle = angle + .pi / 2
        let forkLen: CGFloat = size / 1.5

        ctx.beginPath()
        let tip = CGPoint(x: point.x + forkLen * cos(angle), y: point.y + forkLen * sin(angle))
        ctx.move(to: tip)
        ctx.addLine(to: CGPoint(x: point.x + size/2 * cos(perpAngle), y: point.y + size/2 * sin(perpAngle)))
        ctx.move(to: tip)
        ctx.addLine(to: CGPoint(x: point.x - size/2 * cos(perpAngle), y: point.y - size/2 * sin(perpAngle)))
        ctx.move(to: tip)
        ctx.addLine(to: point)
        ctx.strokePath()
    }

    // MARK: - Text Drawing

    enum TextAlignment {
        case left, center, right
    }

    private func drawText(_ ctx: CGContext, text: String, at point: CGPoint,
                          fontSize: CGFloat, bold: Bool, alignment: TextAlignment,
                          color: CGColor? = nil) {
        let fontName = bold ? config.boldFontName : config.fontName
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)

        let textColor = color ?? config.textColor

        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: textColor
        ]

        let attrStr = CFAttributedStringCreate(kCFAllocatorDefault, text as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let bounds = CTLineGetBoundsWithOptions(line, [])

        var drawX = point.x
        let drawY = point.y

        switch alignment {
        case .left:
            break
        case .center:
            drawX -= bounds.width / 2
        case .right:
            drawX -= bounds.width
        }

        ctx.saveGState()
        ctx.textMatrix = .identity
        ctx.translateBy(x: drawX, y: drawY + bounds.height / 2)
        ctx.scaleBy(x: 1, y: -1)
        ctx.textPosition = .zero
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }

    func measureText(_ text: String, fontSize: CGFloat) -> CGSize {
        let font = CTFontCreateWithName(config.fontName as CFString, fontSize, nil)
        let attributes: [CFString: Any] = [kCTFontAttributeName: font]
        let attrStr = CFAttributedStringCreate(kCFAllocatorDefault, text as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attrStr)
        let bounds = CTLineGetBoundsWithOptions(line, [])
        return CGSize(width: bounds.width, height: bounds.height)
    }

    // MARK: - Image Export

    static func pngData(from image: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
