import XCTest
@testable import MermaidSwift

final class DiagramLayoutTests: XCTestCase {

    // MARK: - Flowchart Layout

    func testFlowchartLayoutSize() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle)
            ],
            edges: [FlowEdge(from: "A", to: "B", label: nil, style: .solid)]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        XCTAssertGreaterThan(layout.size.width, 0)
        XCTAssertGreaterThan(layout.size.height, 0)
    }

    func testFlowchartNodesPositioned() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle),
                FlowNode(id: "C", label: "C", shape: .rectangle)
            ],
            edges: [
                FlowEdge(from: "A", to: "B", label: nil, style: .solid),
                FlowEdge(from: "A", to: "C", label: nil, style: .solid)
            ]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        XCTAssertEqual(layout.nodes.count, 3)
        // A should be in layer 0, B and C in layer 1
        let nodeA = layout.nodes.first { $0.node.id == "A" }!
        let nodeB = layout.nodes.first { $0.node.id == "B" }!
        XCTAssertLessThan(nodeA.frame.minY, nodeB.frame.minY)
    }

    func testFlowchartEdgesPositioned() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle)
            ],
            edges: [FlowEdge(from: "A", to: "B", label: "test", style: .solid)]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        XCTAssertEqual(layout.edges.count, 1)
        XCTAssertNotNil(layout.edges[0].labelPosition)
    }

    func testFlowchartLRLayout() {
        let diagram = FlowchartDiagram(
            direction: .leftToRight,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle)
            ],
            edges: [FlowEdge(from: "A", to: "B", label: nil, style: .solid)]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        let nodeA = layout.nodes.first { $0.node.id == "A" }!
        let nodeB = layout.nodes.first { $0.node.id == "B" }!
        XCTAssertLessThan(nodeA.frame.minX, nodeB.frame.minX)
    }

    func testFlowchartSubgraphsLayout() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle)
            ],
            edges: [FlowEdge(from: "A", to: "B", label: nil, style: .solid)],
            subgraphs: [Subgraph(id: "sg1", label: "Group", nodeIds: ["A", "B"])]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        XCTAssertEqual(layout.subgraphs.count, 1)
        // Subgraph should contain both nodes
        let sgFrame = layout.subgraphs[0].frame
        let nodeA = layout.nodes.first { $0.node.id == "A" }!
        XCTAssertTrue(sgFrame.contains(nodeA.frame.origin))
    }

    func testFlowchartStyleResolution() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [FlowNode(id: "A", label: "A", shape: .rectangle)],
            edges: [],
            classDefs: ["red": NodeStyle(fill: "#f00", stroke: "#333")],
            nodeClassMap: ["A": "red"]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        XCTAssertNotNil(layout.nodes[0].style)
        XCTAssertEqual(layout.nodes[0].style?.fill, "#f00")
    }

    // MARK: - Sequence Diagram Layout

    func testSequenceLayoutSize() {
        let diagram = SequenceDiagram(
            participants: [
                Participant(id: "A", label: "Alice"),
                Participant(id: "B", label: "Bob")
            ],
            messages: [Message(from: "A", to: "B", text: "Hello", style: .solidArrow)]
        )
        let layout = DiagramLayout().layoutSequenceDiagram(diagram)
        XCTAssertGreaterThan(layout.size.width, 0)
        XCTAssertEqual(layout.participants.count, 2)
        XCTAssertEqual(layout.messages.count, 1)
    }

    // MARK: - Pie Chart Layout

    func testPieLayoutSlices() {
        let diagram = PieChartDiagram(title: "Test", slices: [
            PieSlice(label: "A", value: 50),
            PieSlice(label: "B", value: 50)
        ])
        let layout = DiagramLayout().layoutPieChart(diagram)
        XCTAssertEqual(layout.slices.count, 2)
        XCTAssertEqual(layout.slices[0].percentage, 50, accuracy: 0.1)
    }

    func testPieLayoutEmpty() {
        let diagram = PieChartDiagram(title: nil, slices: [])
        let layout = DiagramLayout().layoutPieChart(diagram)
        XCTAssertEqual(layout.slices.count, 0)
    }

    // MARK: - Class Diagram Layout

    func testClassDiagramLayout() {
        let diagram = ClassDiagram(
            classes: [
                ClassDefinition(name: "Animal", properties: [
                    ClassMember(visibility: .public, name: "name", memberType: "String")
                ], methods: [
                    ClassMember(visibility: .public, name: "speak()", memberType: "void")
                ]),
                ClassDefinition(name: "Dog")
            ],
            relationships: [
                ClassRelationship(from: "Dog", to: "Animal", relationshipType: .inheritance)
            ]
        )
        let layout = DiagramLayout().layoutClassDiagram(diagram)
        XCTAssertEqual(layout.classes.count, 2)
        XCTAssertEqual(layout.relationships.count, 1)
        XCTAssertGreaterThan(layout.size.width, 0)
    }

    // MARK: - State Diagram Layout

    func testStateDiagramLayout() {
        let diagram = StateDiagram(
            states: [
                StateNode(id: "[*]"),
                StateNode(id: "Active"),
                StateNode(id: "Idle")
            ],
            transitions: [
                StateTransition(from: "[*]", to: "Active"),
                StateTransition(from: "Active", to: "Idle", label: "timeout"),
                StateTransition(from: "Idle", to: "[*]")
            ]
        )
        let layout = DiagramLayout().layoutStateDiagram(diagram)
        XCTAssertEqual(layout.states.count, 3)
        XCTAssertEqual(layout.transitions.count, 3)
        let startState = layout.states.first { $0.state.id == "[*]" }
        XCTAssertTrue(startState?.isStartEnd ?? false)
    }

    // MARK: - Gantt Chart Layout

    func testGanttLayout() {
        let diagram = GanttDiagram(
            title: "Project",
            sections: [
                GanttSection(name: "Phase 1", tasks: [
                    GanttTask(name: "Task A", id: "a1", startDate: "2024-01-01", duration: "10d"),
                    GanttTask(name: "Task B", id: "a2", status: .critical, afterId: "a1")
                ])
            ]
        )
        let layout = DiagramLayout().layoutGanttChart(diagram)
        XCTAssertEqual(layout.tasks.count, 2)
        XCTAssertEqual(layout.sections.count, 1)
        XCTAssertNotNil(layout.title)
    }

    // MARK: - ER Diagram Layout

    func testERDiagramLayout() {
        let diagram = ERDiagram(
            entities: [
                EREntity(name: "CUSTOMER", attributes: [
                    ERAttribute(attributeType: "int", name: "id", key: .pk),
                    ERAttribute(attributeType: "string", name: "name")
                ]),
                EREntity(name: "ORDER", attributes: [
                    ERAttribute(attributeType: "int", name: "id", key: .pk)
                ])
            ],
            relationships: [
                ERRelationship(from: "CUSTOMER", to: "ORDER", label: "places",
                               fromCardinality: .exactlyOne, toCardinality: .zeroOrMore)
            ]
        )
        let layout = DiagramLayout().layoutERDiagram(diagram)
        XCTAssertEqual(layout.entities.count, 2)
        XCTAssertEqual(layout.relationships.count, 1)
        XCTAssertGreaterThan(layout.size.width, 0)
    }

    // MARK: - Dark Mode Config

    func testDarkModeConfig() {
        let config = LayoutConfig.darkMode
        // Dark background should have low R/G/B values
        let components = config.backgroundColor.components!
        XCTAssertLessThan(components[0], 0.2)  // R
        XCTAssertLessThan(components[1], 0.2)  // G
        // Light text should have high R/G/B values
        let textComponents = config.textColor.components!
        XCTAssertGreaterThan(textComponents[0], 0.8)
    }

    // MARK: - Edge Routing

    func testEdgeRoutingDirectPath() {
        // When no obstacles, edge should have exactly 2 points (direct)
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle)
            ],
            edges: [FlowEdge(from: "A", to: "B", label: nil, style: .solid)]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        XCTAssertEqual(layout.edges[0].points.count, 2)
    }
}
