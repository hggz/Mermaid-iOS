import XCTest
@testable import MermaidSwift

final class DiagramRendererTests: XCTestCase {

    let renderer = DiagramRenderer()
    let layout = DiagramLayout()

    // MARK: - Flowchart Rendering

    func testFlowchartRendersImage() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "Start", shape: .rectangle),
                FlowNode(id: "B", label: "End", shape: .roundedRect),
            ],
            edges: [
                FlowEdge(from: "A", to: "B", label: "Next", style: .solid)
            ]
        )

        let flowLayout = layout.layoutFlowchart(diagram)
        let image = renderer.renderFlowchart(flowLayout)

        XCTAssertNotNil(image)
        XCTAssertTrue(image!.width > 0)
        XCTAssertTrue(image!.height > 0)
    }

    func testFlowchartAllShapes() {
        let shapes: [FlowNode.NodeShape] = [.rectangle, .roundedRect, .stadium,
                                             .diamond, .hexagon, .circle, .asymmetric]
        var nodes: [FlowNode] = []
        var edges: [FlowEdge] = []

        for (i, shape) in shapes.enumerated() {
            nodes.append(FlowNode(id: "N\(i)", label: "Shape \(i)", shape: shape))
            if i > 0 {
                edges.append(FlowEdge(from: "N\(i-1)", to: "N\(i)", label: nil, style: .solid))
            }
        }

        let diagram = FlowchartDiagram(direction: .topToBottom, nodes: nodes, edges: edges)
        let flowLayout = layout.layoutFlowchart(diagram)
        let image = renderer.renderFlowchart(flowLayout)

        XCTAssertNotNil(image, "Should render all node shapes without crashing")
    }

    func testFlowchartEdgeStyles() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle),
                FlowNode(id: "C", label: "C", shape: .rectangle),
                FlowNode(id: "D", label: "D", shape: .rectangle),
            ],
            edges: [
                FlowEdge(from: "A", to: "B", label: nil, style: .solid),
                FlowEdge(from: "B", to: "C", label: nil, style: .dotted),
                FlowEdge(from: "C", to: "D", label: nil, style: .thick),
            ]
        )

        let flowLayout = layout.layoutFlowchart(diagram)
        let image = renderer.renderFlowchart(flowLayout)
        XCTAssertNotNil(image)
    }

    // MARK: - Sequence Diagram Rendering

    func testSequenceDiagramRendersImage() {
        let diagram = SequenceDiagram(
            participants: [
                Participant(id: "Alice", label: "Alice"),
                Participant(id: "Bob", label: "Bob"),
            ],
            messages: [
                Message(from: "Alice", to: "Bob", text: "Hello", style: .solidArrow),
                Message(from: "Bob", to: "Alice", text: "Hi", style: .dottedArrow),
            ]
        )

        let seqLayout = layout.layoutSequenceDiagram(diagram)
        let image = renderer.renderSequenceDiagram(seqLayout)

        XCTAssertNotNil(image)
        XCTAssertTrue(image!.width > 0)
        XCTAssertTrue(image!.height > 0)
    }

    func testSequenceAllMessageStyles() {
        let styles: [Message.MessageStyle] = [
            .solidArrow, .dottedArrow, .solidLine, .dottedLine, .solidCross, .dottedCross
        ]

        var messages: [Message] = []
        for style in styles {
            messages.append(Message(from: "A", to: "B", text: "msg", style: style))
        }

        let diagram = SequenceDiagram(
            participants: [
                Participant(id: "A", label: "Alice"),
                Participant(id: "B", label: "Bob"),
            ],
            messages: messages
        )

        let seqLayout = layout.layoutSequenceDiagram(diagram)
        let image = renderer.renderSequenceDiagram(seqLayout)
        XCTAssertNotNil(image, "Should render all message styles without crashing")
    }

    // MARK: - Pie Chart Rendering

    func testPieChartRendersImage() {
        let diagram = PieChartDiagram(
            title: "Languages",
            slices: [
                PieSlice(label: "Swift", value: 45),
                PieSlice(label: "Kotlin", value: 30),
                PieSlice(label: "Python", value: 25),
            ]
        )

        let pieLayout = layout.layoutPieChart(diagram)
        let image = renderer.renderPieChart(pieLayout)

        XCTAssertNotNil(image)
        XCTAssertTrue(image!.width > 0)
        XCTAssertTrue(image!.height > 0)
    }

    func testPieChartNoTitle() {
        let diagram = PieChartDiagram(
            title: nil,
            slices: [PieSlice(label: "A", value: 100)]
        )

        let pieLayout = layout.layoutPieChart(diagram)
        let image = renderer.renderPieChart(pieLayout)
        XCTAssertNotNil(image)
    }

    // MARK: - PNG Export

    func testPNGExport() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [FlowNode(id: "A", label: "Node", shape: .rectangle)],
            edges: []
        )

        let flowLayout = layout.layoutFlowchart(diagram)
        guard let image = renderer.renderFlowchart(flowLayout) else {
            XCTFail("Failed to render"); return
        }

        let pngData = DiagramRenderer.pngData(from: image)
        XCTAssertNotNil(pngData)
        XCTAssertTrue(pngData!.count > 0)

        // PNG magic bytes
        let bytes = [UInt8](pngData!.prefix(4))
        XCTAssertEqual(bytes[0], 0x89)
        XCTAssertEqual(bytes[1], 0x50) // P
        XCTAssertEqual(bytes[2], 0x4E) // N
        XCTAssertEqual(bytes[3], 0x47) // G
    }
}
