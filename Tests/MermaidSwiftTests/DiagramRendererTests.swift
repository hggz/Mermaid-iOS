import XCTest
@testable import MermaidSwift

final class DiagramRendererTests: XCTestCase {

    // MARK: - Flowchart Rendering

    func testRenderFlowchartProducesImage() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "Start", shape: .roundedRect),
                FlowNode(id: "B", label: "End", shape: .rectangle)
            ],
            edges: [FlowEdge(from: "A", to: "B", label: nil, style: .solid)]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        let image = DiagramRenderer().renderFlowchart(layout)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image!.width, 0)
    }

    func testRenderFlowchartWithSubgraphs() {
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
        let image = DiagramRenderer().renderFlowchart(layout)
        XCTAssertNotNil(image)
    }

    func testRenderFlowchartWithStyles() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [FlowNode(id: "A", label: "Styled", shape: .rectangle)],
            edges: [],
            classDefs: ["custom": NodeStyle(fill: "#ff9999", stroke: "#333333", strokeWidth: 3, color: "#000000")],
            nodeClassMap: ["A": "custom"]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        let image = DiagramRenderer().renderFlowchart(layout)
        XCTAssertNotNil(image)
    }

    func testRenderAllNodeShapes() {
        let shapes: [(String, FlowNode.NodeShape)] = [
            ("rect", .rectangle), ("round", .roundedRect), ("stad", .stadium),
            ("dia", .diamond), ("hex", .hexagon), ("circ", .circle), ("asym", .asymmetric)
        ]
        let nodes = shapes.map { FlowNode(id: $0.0, label: $0.0, shape: $0.1) }
        let diagram = FlowchartDiagram(direction: .topToBottom, nodes: nodes, edges: [])
        let layout = DiagramLayout().layoutFlowchart(diagram)
        let image = DiagramRenderer().renderFlowchart(layout)
        XCTAssertNotNil(image)
    }

    func testRenderAllEdgeStyles() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "A", shape: .rectangle),
                FlowNode(id: "B", label: "B", shape: .rectangle),
                FlowNode(id: "C", label: "C", shape: .rectangle),
                FlowNode(id: "D", label: "D", shape: .rectangle),
                FlowNode(id: "E", label: "E", shape: .rectangle),
            ],
            edges: [
                FlowEdge(from: "A", to: "B", label: "solid", style: .solid),
                FlowEdge(from: "A", to: "C", label: nil, style: .dotted),
                FlowEdge(from: "A", to: "D", label: nil, style: .thick),
                FlowEdge(from: "A", to: "E", label: nil, style: .invisible),
            ]
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        let image = DiagramRenderer().renderFlowchart(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - Sequence Diagram Rendering

    func testRenderSequenceDiagram() {
        let diagram = SequenceDiagram(
            participants: [
                Participant(id: "A", label: "Alice"),
                Participant(id: "B", label: "Bob")
            ],
            messages: [
                Message(from: "A", to: "B", text: "Hello", style: .solidArrow),
                Message(from: "B", to: "A", text: "Hi", style: .dottedArrow)
            ]
        )
        let layout = DiagramLayout().layoutSequenceDiagram(diagram)
        let image = DiagramRenderer().renderSequenceDiagram(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - Pie Chart Rendering

    func testRenderPieChart() {
        let diagram = PieChartDiagram(title: "Languages", slices: [
            PieSlice(label: "Swift", value: 60),
            PieSlice(label: "Kotlin", value: 30),
            PieSlice(label: "Other", value: 10)
        ])
        let layout = DiagramLayout().layoutPieChart(diagram)
        let image = DiagramRenderer().renderPieChart(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - Class Diagram Rendering

    func testRenderClassDiagram() {
        let diagram = ClassDiagram(
            classes: [
                ClassDefinition(name: "Animal", properties: [
                    ClassMember(visibility: .public, name: "name", memberType: "String"),
                    ClassMember(visibility: .private, name: "age", memberType: "Int")
                ], methods: [
                    ClassMember(visibility: .public, name: "speak()", memberType: "void")
                ], annotation: "abstract"),
                ClassDefinition(name: "Dog", properties: [
                    ClassMember(visibility: .public, name: "breed", memberType: "String")
                ], methods: [
                    ClassMember(visibility: .public, name: "fetch()")
                ])
            ],
            relationships: [
                ClassRelationship(from: "Dog", to: "Animal", label: "inherits",
                                  relationshipType: .inheritance)
            ]
        )
        let layout = DiagramLayout().layoutClassDiagram(diagram)
        let image = DiagramRenderer().renderClassDiagram(layout)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image!.width, 0)
    }

    func testRenderClassDiagramAllRelationTypes() {
        let classes = ["A", "B", "C", "D", "E", "F"].map { ClassDefinition(name: $0) }
        let rels: [ClassRelationship] = [
            ClassRelationship(from: "B", to: "A", relationshipType: .inheritance),
            ClassRelationship(from: "A", to: "C", relationshipType: .composition),
            ClassRelationship(from: "A", to: "D", relationshipType: .aggregation),
            ClassRelationship(from: "A", to: "E", relationshipType: .dependency),
            ClassRelationship(from: "A", to: "F", relationshipType: .realization),
        ]
        let layout = DiagramLayout().layoutClassDiagram(ClassDiagram(classes: classes, relationships: rels))
        let image = DiagramRenderer().renderClassDiagram(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - State Diagram Rendering

    func testRenderStateDiagram() {
        let diagram = StateDiagram(
            states: [
                StateNode(id: "[*]"),
                StateNode(id: "Idle", label: "Idle"),
                StateNode(id: "Active", label: "Active", description: "Processing"),
                StateNode(id: "Done", label: "Done")
            ],
            transitions: [
                StateTransition(from: "[*]", to: "Idle"),
                StateTransition(from: "Idle", to: "Active", label: "start"),
                StateTransition(from: "Active", to: "Done"),
                StateTransition(from: "Done", to: "[*]")
            ]
        )
        let layout = DiagramLayout().layoutStateDiagram(diagram)
        let image = DiagramRenderer().renderStateDiagram(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - Gantt Chart Rendering

    func testRenderGanttChart() {
        let diagram = GanttDiagram(
            title: "Sprint Plan",
            sections: [
                GanttSection(name: "Design", tasks: [
                    GanttTask(name: "Mockups", id: "d1", startDate: "2024-01-01", duration: "5d"),
                    GanttTask(name: "Review", id: "d2", status: .active, afterId: "d1")
                ]),
                GanttSection(name: "Dev", tasks: [
                    GanttTask(name: "Implement", id: "v1", status: .critical, startDate: "2024-01-10", duration: "15d"),
                    GanttTask(name: "Test", id: "v2", status: .done, afterId: "v1")
                ])
            ]
        )
        let layout = DiagramLayout().layoutGanttChart(diagram)
        let image = DiagramRenderer().renderGanttChart(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - ER Diagram Rendering

    func testRenderERDiagram() {
        let diagram = ERDiagram(
            entities: [
                EREntity(name: "CUSTOMER", attributes: [
                    ERAttribute(attributeType: "int", name: "id", key: .pk),
                    ERAttribute(attributeType: "string", name: "name"),
                    ERAttribute(attributeType: "string", name: "email", key: .uk)
                ]),
                EREntity(name: "ORDER", attributes: [
                    ERAttribute(attributeType: "int", name: "id", key: .pk),
                    ERAttribute(attributeType: "int", name: "customer_id", key: .fk),
                    ERAttribute(attributeType: "date", name: "created_at")
                ])
            ],
            relationships: [
                ERRelationship(from: "CUSTOMER", to: "ORDER", label: "places",
                               fromCardinality: .exactlyOne, toCardinality: .zeroOrMore)
            ]
        )
        let layout = DiagramLayout().layoutERDiagram(diagram)
        let image = DiagramRenderer().renderERDiagram(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - Dark Mode Rendering

    func testRenderDarkMode() {
        let darkConfig = LayoutConfig.darkMode
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [
                FlowNode(id: "A", label: "Dark", shape: .roundedRect),
                FlowNode(id: "B", label: "Mode", shape: .rectangle)
            ],
            edges: [FlowEdge(from: "A", to: "B", label: "arrow", style: .solid)]
        )
        let layout = DiagramLayout(config: darkConfig).layoutFlowchart(diagram)
        let renderer = DiagramRenderer(config: darkConfig)
        let image = renderer.renderFlowchart(layout)
        XCTAssertNotNil(image)
    }

    func testRenderDarkModePie() {
        let darkConfig = LayoutConfig.darkMode
        let diagram = PieChartDiagram(title: "Dark Pie", slices: [
            PieSlice(label: "A", value: 60),
            PieSlice(label: "B", value: 40)
        ])
        let layout = DiagramLayout(config: darkConfig).layoutPieChart(diagram)
        let image = DiagramRenderer(config: darkConfig).renderPieChart(layout)
        XCTAssertNotNil(image)
    }

    // MARK: - PNG Export

    func testPngExport() {
        let diagram = FlowchartDiagram(
            direction: .topToBottom,
            nodes: [FlowNode(id: "A", label: "Node", shape: .rectangle)],
            edges: []
        )
        let layout = DiagramLayout().layoutFlowchart(diagram)
        let image = DiagramRenderer().renderFlowchart(layout)!
        let data = DiagramRenderer.pngData(from: image)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data!.count, 0)

        // Verify PNG magic bytes
        let bytes = [UInt8](data!)
        XCTAssertEqual(bytes[0], 0x89)
        XCTAssertEqual(bytes[1], 0x50)  // P
        XCTAssertEqual(bytes[2], 0x4E)  // N
        XCTAssertEqual(bytes[3], 0x47)  // G
    }
}
