import XCTest
@testable import MermaidSwift

final class DiagramLayoutTests: XCTestCase {

    let layout = DiagramLayout()

    // MARK: - Flowchart Layout

    func testFlowchartLayoutPositionsNodes() throws {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "Start", shape: .rectangle),
                FlowNode(id: "B", label: "End", shape: .rectangle),
            ],
            edges: [
                FlowEdge(from: "A", to: "B", label: nil, style: .solid)
            ]
        )

        let result = layout.layoutFlowchart(diagram)

        XCTAssertEqual(result.nodes.count, 2)
        XCTAssertEqual(result.edges.count, 1)
        XCTAssertTrue(result.size.width > 0)
        XCTAssertTrue(result.size.height > 0)

        // Node A should be above node B in TD layout
        let nodeA = result.nodes.first { $0.node.id == "A" }
        let nodeB = result.nodes.first { $0.node.id == "B" }
        XCTAssertNotNil(nodeA)
        XCTAssertNotNil(nodeB)
        XCTAssertLessThan(nodeA!.frame.minY, nodeB!.frame.minY)
    }

    func testFlowchartLayoutLR() throws {
        let diagram = FlowchartDiagram(
            direction: .leftToRight,
            nodes: [
                FlowNode(id: "A", label: "Start", shape: .rectangle),
                FlowNode(id: "B", label: "End", shape: .rectangle),
            ],
            edges: [
                FlowEdge(from: "A", to: "B", label: nil, style: .solid)
            ]
        )

        let result = layout.layoutFlowchart(diagram)

        let nodeA = result.nodes.first { $0.node.id == "A" }
        let nodeB = result.nodes.first { $0.node.id == "B" }
        XCTAssertNotNil(nodeA)
        XCTAssertNotNil(nodeB)
        // In LR, A should be left of B
        XCTAssertLessThan(nodeA!.frame.minX, nodeB!.frame.minX)
    }

    func testFlowchartEdgeConnections() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle),
            ],
            edges: [
                FlowEdge(from: "A", to: "B", label: "Yes", style: .solid)
            ]
        )

        let result = layout.layoutFlowchart(diagram)
        let edge = result.edges[0]

        // From point should be below node A, to point above node B
        XCTAssertNotNil(edge.labelPosition)
        XCTAssertTrue(edge.fromPoint.y < edge.toPoint.y) // TD: fromY < toY
    }

    func testFlowchartMultipleLayers() {
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
                FlowEdge(from: "A", to: "C", label: nil, style: .solid),
                FlowEdge(from: "B", to: "D", label: nil, style: .solid),
                FlowEdge(from: "C", to: "D", label: nil, style: .solid),
            ]
        )

        let result = layout.layoutFlowchart(diagram)
        XCTAssertEqual(result.nodes.count, 4)
        XCTAssertEqual(result.edges.count, 4)

        // D should be in the bottom layer
        let nodeA = result.nodes.first { $0.node.id == "A" }!
        let nodeD = result.nodes.first { $0.node.id == "D" }!
        XCTAssertLessThan(nodeA.frame.minY, nodeD.frame.minY)
    }

    // MARK: - Sequence Diagram Layout

    func testSequenceDiagramLayout() {
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

        let result = layout.layoutSequenceDiagram(diagram)

        XCTAssertEqual(result.participants.count, 2)
        XCTAssertEqual(result.messages.count, 2)
        XCTAssertTrue(result.size.width > 0)
        XCTAssertTrue(result.size.height > 0)

        // Alice should be left of Bob
        let alice = result.participants[0]
        let bob = result.participants[1]
        XCTAssertLessThan(alice.lifelineX, bob.lifelineX)

        // Messages should flow downward
        XCTAssertLessThan(result.messages[0].y, result.messages[1].y)
    }

    func testSequenceLifelineExtends() {
        let diagram = SequenceDiagram(
            participants: [Participant(id: "A", label: "A")],
            messages: [
                Message(from: "A", to: "A", text: "Self", style: .solidArrow),
            ]
        )

        let result = layout.layoutSequenceDiagram(diagram)
        let participant = result.participants[0]
        XCTAssertLessThan(participant.lifelineTop, participant.lifelineBottom)
    }

    // MARK: - Pie Chart Layout

    func testPieChartLayout() {
        let diagram = PieChartDiagram(
            title: "Test",
            slices: [
                PieSlice(label: "A", value: 30),
                PieSlice(label: "B", value: 70),
            ]
        )

        let result = layout.layoutPieChart(diagram)

        XCTAssertEqual(result.slices.count, 2)
        XCTAssertEqual(result.title, "Test")
        XCTAssertTrue(result.radius > 0)

        // Check angles sum to 2π
        let totalAngle = result.slices.reduce(CGFloat(0)) { $0 + ($1.endAngle - $1.startAngle) }
        XCTAssertEqual(totalAngle, 2 * .pi, accuracy: 0.01)

        // Check percentages
        XCTAssertEqual(result.slices[0].percentage, 30, accuracy: 0.1)
        XCTAssertEqual(result.slices[1].percentage, 70, accuracy: 0.1)
    }

    func testPieChartEmptyData() {
        let diagram = PieChartDiagram(title: nil, slices: [])
        let result = layout.layoutPieChart(diagram)
        XCTAssertTrue(result.slices.isEmpty)
    }

    func testPieChartSingleSlice() {
        let diagram = PieChartDiagram(
            title: nil,
            slices: [PieSlice(label: "Only", value: 100)]
        )

        let result = layout.layoutPieChart(diagram)
        XCTAssertEqual(result.slices.count, 1)
        XCTAssertEqual(result.slices[0].percentage, 100, accuracy: 0.1)
    }
}
