import XCTest
@testable import MermaidSwift

final class MermaidParserTests: XCTestCase {

    let parser = MermaidParser()

    // MARK: - Error Cases

    func testEmptyInput() {
        XCTAssertThrowsError(try parser.parse("")) { error in
            XCTAssertEqual(error as? MermaidParser.ParseError, .emptyInput)
        }
    }

    func testWhitespaceOnlyInput() {
        XCTAssertThrowsError(try parser.parse("   \n  \n  ")) { error in
            XCTAssertEqual(error as? MermaidParser.ParseError, .emptyInput)
        }
    }

    func testUnknownDiagramType() {
        XCTAssertThrowsError(try parser.parse("timeline\n  2024: Something")) { error in
            if case MermaidParser.ParseError.unknownDiagramType(let type) = error {
                XCTAssertTrue(type.hasPrefix("timeline"))
            } else {
                XCTFail("Expected unknownDiagramType error")
            }
        }
    }

    // MARK: - Flowchart Parsing

    func testFlowchartBasic() throws {
        let diagram = try parser.parse("""
        flowchart TD
            A[Start] --> B[End]
        """)

        let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
        XCTAssertEqual(flowchart.direction, .topToBottom)
        XCTAssertEqual(flowchart.nodes.count, 2)
        XCTAssertEqual(flowchart.edges.count, 1)

        let nodeIds = Set(flowchart.nodes.map(\.id))
        XCTAssertTrue(nodeIds.contains("A"))
        XCTAssertTrue(nodeIds.contains("B"))

        let edge = flowchart.edges[0]
        XCTAssertEqual(edge.from, "A")
        XCTAssertEqual(edge.to, "B")
        XCTAssertEqual(edge.style, .solid)
        XCTAssertNil(edge.label)
    }

    func testFlowchartDirections() throws {
        for (dir, expected) in [("TD", FlowchartDiagram.FlowDirection.topToBottom),
                                 ("TB", .topDown),
                                 ("BT", .bottomToTop),
                                 ("LR", .leftToRight),
                                 ("RL", .rightToLeft)] {
            let diagram = try parser.parse("flowchart \(dir)\n  A --> B")
            let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
            XCTAssertEqual(flowchart.direction, expected, "Direction \(dir) should parse correctly")
        }
    }

    func testFlowchartGraphKeyword() throws {
        let diagram = try parser.parse("graph LR\n  A --> B")
        let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
        XCTAssertEqual(flowchart.direction, .leftToRight)
    }

    func testFlowchartNodeShapes() throws {
        let diagram = try parser.parse("""
        flowchart TD
            A[Rectangle] --> B(Rounded)
            B --> C{Diamond}
            C --> D([Stadium])
            D --> E((Circle))
            E --> F{{Hexagon}}
        """)

        let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
        let nodeMap = Dictionary(uniqueKeysWithValues: flowchart.nodes.map { ($0.id, $0) })

        XCTAssertEqual(nodeMap["A"]?.shape, .rectangle)
        XCTAssertEqual(nodeMap["A"]?.label, "Rectangle")
        XCTAssertEqual(nodeMap["B"]?.shape, .roundedRect)
        XCTAssertEqual(nodeMap["B"]?.label, "Rounded")
        XCTAssertEqual(nodeMap["C"]?.shape, .diamond)
        XCTAssertEqual(nodeMap["D"]?.shape, .stadium)
        XCTAssertEqual(nodeMap["E"]?.shape, .circle)
        XCTAssertEqual(nodeMap["F"]?.shape, .hexagon)
    }

    func testFlowchartEdgeStyles() throws {
        let diagram = try parser.parse("""
        flowchart TD
            A --> B
            B -.-> C
            C ==> D
        """)

        let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
        XCTAssertEqual(flowchart.edges.count, 3)
        XCTAssertEqual(flowchart.edges[0].style, .solid)
        XCTAssertEqual(flowchart.edges[1].style, .dotted)
        XCTAssertEqual(flowchart.edges[2].style, .thick)
    }

    func testFlowchartEdgeLabel() throws {
        let diagram = try parser.parse("""
        flowchart TD
            A -->|Yes| B
            A -->|No| C
        """)

        let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
        XCTAssertEqual(flowchart.edges[0].label, "Yes")
        XCTAssertEqual(flowchart.edges[1].label, "No")
    }

    func testFlowchartMultipleEdges() throws {
        let diagram = try parser.parse("""
        flowchart TD
            A[Start] --> B{Decision}
            B -->|Yes| C[Do thing]
            B -->|No| D[Skip]
            C --> E[End]
            D --> E
        """)

        let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
        XCTAssertEqual(flowchart.edges.count, 5)
        XCTAssertEqual(flowchart.nodes.count, 5)
    }

    func testFlowchartComments() throws {
        let diagram = try parser.parse("""
        flowchart TD
            %% This is a comment
            A --> B
        """)

        let flowchart = try XCTUnwrap(diagram as? FlowchartDiagram)
        XCTAssertEqual(flowchart.nodes.count, 2)
    }

    // MARK: - Sequence Diagram Parsing

    func testSequenceDiagramBasic() throws {
        let diagram = try parser.parse("""
        sequenceDiagram
            Alice->>Bob: Hello Bob
            Bob-->>Alice: Hi Alice
        """)

        let seq = try XCTUnwrap(diagram as? SequenceDiagram)
        XCTAssertEqual(seq.participants.count, 2)
        XCTAssertEqual(seq.messages.count, 2)

        XCTAssertEqual(seq.participants[0].id, "Alice")
        XCTAssertEqual(seq.participants[1].id, "Bob")

        XCTAssertEqual(seq.messages[0].from, "Alice")
        XCTAssertEqual(seq.messages[0].to, "Bob")
        XCTAssertEqual(seq.messages[0].text, "Hello Bob")
        XCTAssertEqual(seq.messages[0].style, .solidArrow)

        XCTAssertEqual(seq.messages[1].style, .dottedArrow)
    }

    func testSequenceDiagramExplicitParticipants() throws {
        let diagram = try parser.parse("""
        sequenceDiagram
            participant A as Alice
            participant B as Bob
            A->>B: Hello
        """)

        let seq = try XCTUnwrap(diagram as? SequenceDiagram)
        XCTAssertEqual(seq.participants[0].id, "A")
        XCTAssertEqual(seq.participants[0].label, "Alice")
        XCTAssertEqual(seq.participants[1].id, "B")
        XCTAssertEqual(seq.participants[1].label, "Bob")
    }

    func testSequenceDiagramMessageStyles() throws {
        let diagram = try parser.parse("""
        sequenceDiagram
            A->>B: solid arrow
            B-->>A: dotted arrow
            A->B: solid line
            B-->A: dotted line
            A-xB: cross
            B--xA: dotted cross
        """)

        let seq = try XCTUnwrap(diagram as? SequenceDiagram)
        XCTAssertEqual(seq.messages.count, 6)
        XCTAssertEqual(seq.messages[0].style, .solidArrow)
        XCTAssertEqual(seq.messages[1].style, .dottedArrow)
        XCTAssertEqual(seq.messages[2].style, .solidLine)
        XCTAssertEqual(seq.messages[3].style, .dottedLine)
        XCTAssertEqual(seq.messages[4].style, .solidCross)
        XCTAssertEqual(seq.messages[5].style, .dottedCross)
    }

    func testSequenceDiagramAutoParticipants() throws {
        // When no "participant" declaration, participants are auto-created from messages
        let diagram = try parser.parse("""
        sequenceDiagram
            Server->>Database: Query
            Database-->>Server: Results
        """)

        let seq = try XCTUnwrap(diagram as? SequenceDiagram)
        XCTAssertEqual(seq.participants.count, 2)
        let ids = seq.participants.map(\.id)
        XCTAssertTrue(ids.contains("Server"))
        XCTAssertTrue(ids.contains("Database"))
    }

    func testSequenceDiagramActor() throws {
        let diagram = try parser.parse("""
        sequenceDiagram
            actor User
            User->>System: Login
        """)

        let seq = try XCTUnwrap(diagram as? SequenceDiagram)
        XCTAssertEqual(seq.participants.count, 2)
        XCTAssertEqual(seq.participants[0].id, "User")
    }

    // MARK: - Pie Chart Parsing

    func testPieChartBasic() throws {
        let diagram = try parser.parse("""
        pie title Languages
            "Swift" : 45
            "Kotlin" : 30
            "Python" : 25
        """)

        let pie = try XCTUnwrap(diagram as? PieChartDiagram)
        XCTAssertEqual(pie.title, "Languages")
        XCTAssertEqual(pie.slices.count, 3)

        XCTAssertEqual(pie.slices[0].label, "Swift")
        XCTAssertEqual(pie.slices[0].value, 45, accuracy: 0.01)

        XCTAssertEqual(pie.slices[1].label, "Kotlin")
        XCTAssertEqual(pie.slices[1].value, 30, accuracy: 0.01)
    }

    func testPieChartNoTitle() throws {
        let diagram = try parser.parse("""
        pie
            "A" : 50
            "B" : 50
        """)

        let pie = try XCTUnwrap(diagram as? PieChartDiagram)
        XCTAssertNil(pie.title)
        XCTAssertEqual(pie.slices.count, 2)
    }

    func testPieChartDecimalValues() throws {
        let diagram = try parser.parse("""
        pie title Test
            "Alpha" : 33.3
            "Beta" : 66.7
        """)

        let pie = try XCTUnwrap(diagram as? PieChartDiagram)
        XCTAssertEqual(pie.slices[0].value, 33.3, accuracy: 0.01)
        XCTAssertEqual(pie.slices[1].value, 66.7, accuracy: 0.01)
    }

    func testPieChartSeparateTitleLine() throws {
        let diagram = try parser.parse("""
        pie
            title My Chart
            "A" : 100
        """)

        let pie = try XCTUnwrap(diagram as? PieChartDiagram)
        XCTAssertEqual(pie.title, "My Chart")
    }

    // MARK: - Diagram Type Detection

    func testDiagramTypeDetection() throws {
        let flowchart = try parser.parse("flowchart TD\n  A --> B")
        XCTAssertTrue(flowchart is FlowchartDiagram)

        let graph = try parser.parse("graph LR\n  A --> B")
        XCTAssertTrue(graph is FlowchartDiagram)

        let seq = try parser.parse("sequenceDiagram\n  A->>B: hi")
        XCTAssertTrue(seq is SequenceDiagram)

        let pie = try parser.parse("pie\n  \"A\" : 1")
        XCTAssertTrue(pie is PieChartDiagram)
    }
}
