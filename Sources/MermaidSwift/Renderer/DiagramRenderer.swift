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

        // Background
        fillBackground(ctx, size: size)

        // Draw edges first (behind nodes)
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

        // Draw lifelines
        for p in layout.participants {
            drawLifeline(ctx, participant: p)
        }

        // Draw participant boxes
        for p in layout.participants {
            drawParticipantBox(ctx, participant: p)
        }

        // Draw messages
        for msg in layout.messages {
            drawMessage(ctx, message: msg)
        }

        return ctx.makeImage()
    }

    func renderPieChart(_ layout: DiagramLayout.PieLayout) -> CGImage? {
        let size = layout.size
        guard let ctx = createContext(size: size) else { return nil }

        fillBackground(ctx, size: size)

        // Title
        if let title = layout.title {
            drawText(ctx, text: title, at: layout.titlePosition,
                     fontSize: config.titleFontSize, bold: true, alignment: .center)
        }

        // Draw slices
        for slice in layout.slices {
            drawPieSlice(ctx, slice: slice, center: layout.center, radius: layout.radius)
        }

        // Draw legend
        drawPieLegend(ctx, slices: layout.slices, center: layout.center, radius: layout.radius)

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
        // Flip coordinate system to match top-left origin
        ctx.translateBy(x: 0, y: size.height)
        ctx.scaleBy(x: 1, y: -1)

        // Anti-aliasing
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.setShouldSmoothFonts(true)

        return ctx
    }

    private func fillBackground(_ ctx: CGContext, size: CGSize) {
        ctx.setFillColor(config.backgroundColor)
        ctx.fill(CGRect(origin: .zero, size: size))
    }

    // MARK: - Flowchart Drawing

    private func drawFlowNode(_ ctx: CGContext, node: PositionedNode) {
        let frame = node.frame

        ctx.saveGState()
        ctx.setFillColor(config.nodeColor)
        ctx.setStrokeColor(config.nodeBorderColor)
        ctx.setLineWidth(config.lineWidth)

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

        // Draw label
        drawText(ctx, text: node.node.label,
                 at: CGPoint(x: frame.midX, y: frame.midY),
                 fontSize: config.fontSize, bold: false, alignment: .center)
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

        ctx.beginPath()
        ctx.move(to: edge.fromPoint)
        ctx.addLine(to: edge.toPoint)
        ctx.strokePath()

        // Draw arrowhead
        drawArrowhead(ctx, from: edge.fromPoint, to: edge.toPoint)

        ctx.restoreGState()

        // Edge label
        if let label = edge.edge.label, let pos = edge.labelPosition {
            // Draw white background for label legibility
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

        // Arrowhead
        switch message.message.style {
        case .solidArrow, .dottedArrow:
            drawArrowhead(ctx, from: fromPt, to: toPt)
        case .solidCross, .dottedCross:
            drawCross(ctx, at: toPt)
        default:
            drawArrowhead(ctx, from: fromPt, to: toPt)
        }

        ctx.restoreGState()

        // Label
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
            // Color swatch
            let swatchRect = CGRect(x: legendX, y: legendY - 6, width: 12, height: 12)
            ctx.saveGState()
            ctx.setFillColor(slice.color)
            ctx.fill(swatchRect)
            ctx.restoreGState()

            // Label
            let text = String(format: "%@ (%.1f%%)", slice.slice.label, slice.percentage)
            drawText(ctx, text: text,
                     at: CGPoint(x: legendX + 20, y: legendY),
                     fontSize: config.fontSize - 2, bold: false, alignment: .left)

            legendY += 24
        }
    }

    // MARK: - Text Drawing

    enum TextAlignment {
        case left, center, right
    }

    private func drawText(_ ctx: CGContext, text: String, at point: CGPoint,
                          fontSize: CGFloat, bold: Bool, alignment: TextAlignment) {
        let fontName = bold ? config.boldFontName : config.fontName
        guard let font = CTFontCreateWithName(fontName as CFString, fontSize, nil) as CTFont? else { return }

        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: config.textColor
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

        // CoreGraphics has flipped coordinates in our context, so we need to handle text specially
        ctx.saveGState()
        ctx.textMatrix = .identity
        // Un-flip for text
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

    /// Convert a CGImage to PNG data.
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
