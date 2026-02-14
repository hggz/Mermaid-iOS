import XCTest
@testable import MermaidSwift

final class MermaidParserTests: XCTestCase {

    let parser = MermaidParser()

    // MARK: - Error Handling

    func testEmptyInput() {
        XCTAssertThrowsError(try parser.parse("")) { error in
            XCTAssertEqual(error as? MermaidParser.ParseError, .emptyInput)
        }
    }

    func testWhitespaceOnlyInput() {
        XCTAssertThrowsError(try parser.parse("   \n\n  ")) { error in
            XCTAssertEqual(error as? MermaidParser.ParseError, .emptyInput)
        }
    }

    func testUnknownDiagramType() {
        XCTAssertThrowsError(try parser.parse("unknown\n  A --> B")) { error in
            if case .unknownDiagramType(let type) = error as? MermaidParser.ParseError {
                XCTAssertEqual(type, "unknown")
            } else {
                XCTFail("Expected unknownDiagramType error")
            }
        }
    }

    // MARK: - Flowchart: Directions

    func testFlowchartTD() throws {
        let diagram = try parser.parse("flowchart TD\n  A --> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.direction, .topToBottom)
    }

    func testFlowchartLR() throws {
        let diagram = try parser.parse("flowchart LR\n  A --> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.direction, .leftToRight)
    }

    func testFlowchartBT() throws {
        let diagram = try parser.parse("flowchart BT\n  A --> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.direction, .bottomToTop)
    }

    func testFlowchartRL() throws {
        let diagram = try parser.parse("flowchart RL\n  A --> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.direction, .rightToLeft)
    }

    func testGraphKeyword() throws {
        let diagram = try parser.parse("graph LR\n  A --> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.direction, .leftToRight)
    }

    // MARK: - Flowchart: Node Shapes

    func testRectangleNode() throws {
        let diagram = try parser.parse("flowchart TD\n  A[Hello]") as! FlowchartDiagram
        let node = diagram.nodes.first { $0.id == "A" }!
        XCTAssertEqual(node.shape, .rectangle)
        XCTAssertEqual(node.label, "Hello")
    }

    func testRoundedRectNode() throws {
        let diagram = try parser.parse("flowchart TD\n  A(Hello)") as! FlowchartDiagram
        let node = diagram.nodes.first { $0.id == "A" }!
        XCTAssertEqual(node.shape, .roundedRect)
    }

    func testStadiumNode() throws {
        let diagram = try parser.parse("flowchart TD\n  A([Hello])") as! FlowchartDiagram
        let node = diagram.nodes.first { $0.id == "A" }!
        XCTAssertEqual(node.shape, .stadium)
    }

    func testDiamondNode() throws {
        let diagram = try parser.parse("flowchart TD\n  A{Hello}") as! FlowchartDiagram
        let node = diagram.nodes.first { $0.id == "A" }!
        XCTAssertEqual(node.shape, .diamond)
    }

    func testHexagonNode() throws {
        let diagram = try parser.parse("flowchart TD\n  A{{Hello}}") as! FlowchartDiagram
        let node = diagram.nodes.first { $0.id == "A" }!
        XCTAssertEqual(node.shape, .hexagon)
    }

    func testCircleNode() throws {
        let diagram = try parser.parse("flowchart TD\n  A((Hello))") as! FlowchartDiagram
        let node = diagram.nodes.first { $0.id == "A" }!
        XCTAssertEqual(node.shape, .circle)
    }

    func testAsymmetricNode() throws {
        let diagram = try parser.parse("flowchart TD\n  A>Hello]") as! FlowchartDiagram
        let node = diagram.nodes.first { $0.id == "A" }!
        XCTAssertEqual(node.shape, .asymmetric)
    }

    // MARK: - Flowchart: Edge Styles

    func testSolidEdge() throws {
        let diagram = try parser.parse("flowchart TD\n  A --> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.edges.count, 1)
        XCTAssertEqual(diagram.edges[0].style, .solid)
    }

    func testDottedEdge() throws {
        let diagram = try parser.parse("flowchart TD\n  A -.-> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.edges[0].style, .dotted)
    }

    func testThickEdge() throws {
        let diagram = try parser.parse("flowchart TD\n  A ==> B") as! FlowchartDiagram
        XCTAssertEqual(diagram.edges[0].style, .thick)
    }

    func testInvisibleEdge() throws {
        let diagram = try parser.parse("flowchart TD\n  A ~~~ B") as! FlowchartDiagram
        XCTAssertEqual(diagram.edges[0].style, .invisible)
    }

    func testEdgeWithLabel() throws {
        let diagram = try parser.parse("flowchart TD\n  A -->|yes| B") as! FlowchartDiagram
        XCTAssertEqual(diagram.edges[0].label, "yes")
        XCTAssertEqual(diagram.edges[0].from, "A")
        XCTAssertEqual(diagram.edges[0].to, "B")
    }

    // MARK: - Flowchart: Subgraphs

    func testSubgraph() throws {
        let input = """
        flowchart TD
          subgraph sg1 [My Group]
            A[Node A]
            B[Node B]
            A --> B
          end
          C --> A
        """
        let diagram = try parser.parse(input) as! FlowchartDiagram
        XCTAssertEqual(diagram.subgraphs.count, 1)
        XCTAssertEqual(diagram.subgraphs[0].id, "sg1")
        XCTAssertEqual(diagram.subgraphs[0].label, "My Group")
        XCTAssertTrue(diagram.subgraphs[0].nodeIds.contains("A"))
        XCTAssertTrue(diagram.subgraphs[0].nodeIds.contains("B"))
    }

    func testNestedSubgraphs() throws {
        let input = """
        flowchart TD
          subgraph outer [Outer]
            A --> B
            subgraph inner [Inner]
              C --> D
            end
          end
        """
        let diagram = try parser.parse(input) as! FlowchartDiagram
        XCTAssertEqual(diagram.subgraphs.count, 2)
    }

    // MARK: - Flowchart: Style Directives

    func testClassDef() throws {
        let input = """
        flowchart TD
          A[Node A]
          classDef red fill:#f99,stroke:#333,stroke-width:2px,color:#000
        """
        let diagram = try parser.parse(input) as! FlowchartDiagram
        XCTAssertNotNil(diagram.classDefs["red"])
        XCTAssertEqual(diagram.classDefs["red"]?.fill, "#f99")
        XCTAssertEqual(diagram.classDefs["red"]?.stroke, "#333")
        XCTAssertEqual(diagram.classDefs["red"]?.strokeWidth, 2)
        XCTAssertEqual(diagram.classDefs["red"]?.color, "#000")
    }

    func testClassDirective() throws {
        let input = """
        flowchart TD
          A[Node A]
          B[Node B]
          classDef blue fill:#66f
          class A,B blue
        """
        let diagram = try parser.parse(input) as! FlowchartDiagram
        XCTAssertEqual(diagram.nodeClassMap["A"], "blue")
        XCTAssertEqual(diagram.nodeClassMap["B"], "blue")
    }

    func testStyleDirective() throws {
        let input = """
        flowchart TD
          A[Node A]
          style A fill:#f9f,stroke:#333
        """
        let diagram = try parser.parse(input) as! FlowchartDiagram
        XCTAssertNotNil(diagram.nodeClassMap["A"])
        let className = diagram.nodeClassMap["A"]!
        XCTAssertNotNil(diagram.classDefs[className])
        XCTAssertEqual(diagram.classDefs[className]?.fill, "#f9f")
    }

    // MARK: - Flowchart: Comments

    func testCommentsAreSkipped() throws {
        let input = """
        flowchart TD
          %% This is a comment
          A --> B
        """
        let diagram = try parser.parse(input) as! FlowchartDiagram
        XCTAssertEqual(diagram.nodes.count, 2)
        XCTAssertEqual(diagram.edges.count, 1)
    }

    // MARK: - Sequence Diagram

    func testSequenceDiagram() throws {
        let input = """
        sequenceDiagram
          participant Alice
          participant Bob
          Alice->>Bob: Hello Bob
          Bob-->>Alice: Hi Alice
        """
        let diagram = try parser.parse(input) as! SequenceDiagram
        XCTAssertEqual(diagram.participants.count, 2)
        XCTAssertEqual(diagram.participants[0].id, "Alice")
        XCTAssertEqual(diagram.messages.count, 2)
        XCTAssertEqual(diagram.messages[0].style, .solidArrow)
        XCTAssertEqual(diagram.messages[1].style, .dottedArrow)
    }

    func testSequenceWithAlias() throws {
        let input = """
        sequenceDiagram
          participant A as Alice
          participant B as Bob
          A->>B: Hello
        """
        let diagram = try parser.parse(input) as! SequenceDiagram
        XCTAssertEqual(diagram.participants[0].id, "A")
        XCTAssertEqual(diagram.participants[0].label, "Alice")
    }

    func testSequenceActor() throws {
        let input = """
        sequenceDiagram
          actor User
          User->>System: Login
        """
        let diagram = try parser.parse(input) as! SequenceDiagram
        XCTAssertEqual(diagram.participants[0].id, "User")
    }

    func testSequenceAllArrowStyles() throws {
        let input = """
        sequenceDiagram
          A->>B: solid arrow
          A-->>B: dotted arrow
          A->B: solid line
          A-->B: dotted line
          A-xB: solid cross
          A--xB: dotted cross
        """
        let diagram = try parser.parse(input) as! SequenceDiagram
        XCTAssertEqual(diagram.messages[0].style, .solidArrow)
        XCTAssertEqual(diagram.messages[1].style, .dottedArrow)
        XCTAssertEqual(diagram.messages[2].style, .solidLine)
        XCTAssertEqual(diagram.messages[3].style, .dottedLine)
        XCTAssertEqual(diagram.messages[4].style, .solidCross)
        XCTAssertEqual(diagram.messages[5].style, .dottedCross)
    }

    func testSequenceAutoRegisterParticipants() throws {
        let input = """
        sequenceDiagram
          Alice->>Bob: Hello
        """
        let diagram = try parser.parse(input) as! SequenceDiagram
        XCTAssertEqual(diagram.participants.count, 2)
    }

    // MARK: - Pie Chart

    func testPieChart() throws {
        let input = """
        pie title Pets
          "Dogs" : 386
          "Cats" : 85
          "Rats" : 15
        """
        let diagram = try parser.parse(input) as! PieChartDiagram
        XCTAssertEqual(diagram.title, "Pets")
        XCTAssertEqual(diagram.slices.count, 3)
        XCTAssertEqual(diagram.slices[0].label, "Dogs")
        XCTAssertEqual(diagram.slices[0].value, 386)
    }

    func testPieTitleOnSeparateLine() throws {
        let input = """
        pie
          title My Chart
          "A" : 50
          "B" : 50
        """
        let diagram = try parser.parse(input) as! PieChartDiagram
        XCTAssertEqual(diagram.title, "My Chart")
    }

    func testPieNoTitle() throws {
        let input = """
        pie
          "A" : 30
          "B" : 70
        """
        let diagram = try parser.parse(input) as! PieChartDiagram
        XCTAssertNil(diagram.title)
        XCTAssertEqual(diagram.slices.count, 2)
    }

    // MARK: - Class Diagram

    func testClassDiagramBasic() throws {
        let input = """
        classDiagram
          class Animal {
            +String name
            +makeSound() void
          }
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.classes.count, 1)
        XCTAssertEqual(diagram.classes[0].name, "Animal")
        XCTAssertEqual(diagram.classes[0].properties.count, 1)
        XCTAssertEqual(diagram.classes[0].methods.count, 1)
    }

    func testClassMemberVisibilities() throws {
        let input = """
        classDiagram
          class MyClass {
            +publicProp
            -privateProp
            #protectedProp
            ~packageProp
          }
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        let cls = diagram.classes[0]
        XCTAssertEqual(cls.properties[0].visibility, .public)
        XCTAssertEqual(cls.properties[1].visibility, .private)
        XCTAssertEqual(cls.properties[2].visibility, .protected)
        XCTAssertEqual(cls.properties[3].visibility, .packagePrivate)
    }

    func testClassInheritance() throws {
        let input = """
        classDiagram
          Animal <|-- Dog
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships.count, 1)
        XCTAssertEqual(diagram.relationships[0].relationshipType, .inheritance)
        XCTAssertEqual(diagram.relationships[0].from, "Dog")
        XCTAssertEqual(diagram.relationships[0].to, "Animal")
    }

    func testClassComposition() throws {
        let input = """
        classDiagram
          Car *-- Engine
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships[0].relationshipType, .composition)
    }

    func testClassAggregation() throws {
        let input = """
        classDiagram
          Pond o-- Duck
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships[0].relationshipType, .aggregation)
    }

    func testClassAssociation() throws {
        let input = """
        classDiagram
          Student --> Course
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships[0].relationshipType, .association)
    }

    func testClassDependency() throws {
        let input = """
        classDiagram
          ClassA ..> ClassB
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships[0].relationshipType, .dependency)
    }

    func testClassRealization() throws {
        let input = """
        classDiagram
          ClassA ..|> Interface
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships[0].relationshipType, .realization)
    }

    func testClassRelationshipWithLabel() throws {
        let input = """
        classDiagram
          Animal <|-- Dog : inherits
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships[0].label, "inherits")
    }

    func testClassInlineMembers() throws {
        let input = """
        classDiagram
          class Dog
          Dog : +fetch() void
          Dog : +String breed
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        let dog = diagram.classes.first { $0.name == "Dog" }!
        XCTAssertEqual(dog.methods.count, 1)
        XCTAssertEqual(dog.properties.count, 1)
    }

    func testClassAnnotation() throws {
        let input = """
        classDiagram
          <<interface>> Flyable
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        let flyable = diagram.classes.first { $0.name == "Flyable" }!
        XCTAssertEqual(flyable.annotation, "interface")
    }

    func testClassWithCardinality() throws {
        let input = """
        classDiagram
          "1" Customer --> "0..*" Order
        """
        let diagram = try parser.parse(input) as! ClassDiagram
        XCTAssertEqual(diagram.relationships[0].fromCardinality, "1")
        XCTAssertEqual(diagram.relationships[0].toCardinality, "0..*")
    }

    // MARK: - State Diagram

    func testStateDiagramBasic() throws {
        let input = """
        stateDiagram-v2
          [*] --> Still
          Still --> Moving
          Moving --> Crash
          Crash --> [*]
        """
        let diagram = try parser.parse(input) as! StateDiagram
        XCTAssertGreaterThanOrEqual(diagram.states.count, 3) // Still, Moving, Crash + [*]
        XCTAssertEqual(diagram.transitions.count, 4)
    }

    func testStateDiagramWithLabels() throws {
        let input = """
        stateDiagram-v2
          Still --> Moving : start
          Moving --> Crash : collision
        """
        let diagram = try parser.parse(input) as! StateDiagram
        XCTAssertEqual(diagram.transitions[0].label, "start")
        XCTAssertEqual(diagram.transitions[1].label, "collision")
    }

    func testStateDiagramStartEnd() throws {
        let input = """
        stateDiagram-v2
          [*] --> Active
          Active --> [*]
        """
        let diagram = try parser.parse(input) as! StateDiagram
        let startEnd = diagram.states.first { $0.id == "[*]" }
        XCTAssertNotNil(startEnd)
    }

    func testStateDiagramDescription() throws {
        let input = """
        stateDiagram-v2
          state "Not moving" as Still
          Still --> Moving
        """
        let diagram = try parser.parse(input) as! StateDiagram
        let still = diagram.states.first { $0.id == "Still" }
        XCTAssertNotNil(still)
        XCTAssertEqual(still?.description, "Not moving")
    }

    // MARK: - Gantt Chart

    func testGanttBasic() throws {
        let input = """
        gantt
          title My Project
          dateFormat YYYY-MM-DD
          section Planning
            Research :a1, 2024-01-01, 30d
            Design :a2, after a1, 20d
        """
        let diagram = try parser.parse(input) as! GanttDiagram
        XCTAssertEqual(diagram.title, "My Project")
        XCTAssertEqual(diagram.dateFormat, "YYYY-MM-DD")
        XCTAssertEqual(diagram.sections.count, 1)
        XCTAssertEqual(diagram.sections[0].name, "Planning")
        XCTAssertEqual(diagram.sections[0].tasks.count, 2)
    }

    func testGanttTaskStatuses() throws {
        let input = """
        gantt
          section Tasks
            Done task :done, a1, 2024-01-01, 5d
            Active task :active, a2, 2024-01-06, 5d
            Critical task :crit, a3, 2024-01-11, 5d
        """
        let diagram = try parser.parse(input) as! GanttDiagram
        XCTAssertEqual(diagram.sections[0].tasks[0].status, .done)
        XCTAssertEqual(diagram.sections[0].tasks[1].status, .active)
        XCTAssertEqual(diagram.sections[0].tasks[2].status, .critical)
    }

    func testGanttMultipleSections() throws {
        let input = """
        gantt
          section Phase 1
            Task A :a1, 2024-01-01, 10d
          section Phase 2
            Task B :b1, 2024-01-11, 10d
        """
        let diagram = try parser.parse(input) as! GanttDiagram
        XCTAssertEqual(diagram.sections.count, 2)
        XCTAssertEqual(diagram.sections[0].name, "Phase 1")
        XCTAssertEqual(diagram.sections[1].name, "Phase 2")
    }

    func testGanttAfterDependency() throws {
        let input = """
        gantt
          section Tasks
            First :a1, 2024-01-01, 10d
            Second :a2, after a1, 5d
        """
        let diagram = try parser.parse(input) as! GanttDiagram
        XCTAssertEqual(diagram.sections[0].tasks[1].afterId, "a1")
    }

    // MARK: - ER Diagram

    func testERDiagramBasic() throws {
        let input = """
        erDiagram
          CUSTOMER ||--o{ ORDER : places
          ORDER ||--|{ LINE_ITEM : contains
        """
        let diagram = try parser.parse(input) as! ERDiagram
        XCTAssertGreaterThanOrEqual(diagram.entities.count, 3)
        XCTAssertEqual(diagram.relationships.count, 2)
    }

    func testERDiagramCardinalities() throws {
        let input = """
        erDiagram
          CUSTOMER ||--o{ ORDER : places
        """
        let diagram = try parser.parse(input) as! ERDiagram
        XCTAssertEqual(diagram.relationships[0].fromCardinality, .exactlyOne)
        XCTAssertEqual(diagram.relationships[0].toCardinality, .zeroOrMore)
    }

    func testERDiagramEntityAttributes() throws {
        let input = """
        erDiagram
          CUSTOMER {
            string name
            int id PK
            string email UK
          }
        """
        let diagram = try parser.parse(input) as! ERDiagram
        let customer = diagram.entities.first { $0.name == "CUSTOMER" }!
        XCTAssertEqual(customer.attributes.count, 3)
        XCTAssertEqual(customer.attributes[0].attributeType, "string")
        XCTAssertEqual(customer.attributes[0].name, "name")
        XCTAssertNil(customer.attributes[0].key)
        XCTAssertEqual(customer.attributes[1].key, .pk)
        XCTAssertEqual(customer.attributes[2].key, .uk)
    }

    func testERDiagramRelationshipLabel() throws {
        let input = """
        erDiagram
          CUSTOMER ||--o{ ORDER : "places orders"
        """
        let diagram = try parser.parse(input) as! ERDiagram
        XCTAssertEqual(diagram.relationships[0].label, "places orders")
    }

    func testERDiagramOneToOne() throws {
        let input = """
        erDiagram
          PERSON ||--|| PASSPORT : has
        """
        let diagram = try parser.parse(input) as! ERDiagram
        XCTAssertEqual(diagram.relationships[0].fromCardinality, .exactlyOne)
        XCTAssertEqual(diagram.relationships[0].toCardinality, .exactlyOne)
    }

    func testERDiagramOneToMany() throws {
        let input = """
        erDiagram
          DEPARTMENT ||--|{ EMPLOYEE : employs
        """
        let diagram = try parser.parse(input) as! ERDiagram
        XCTAssertEqual(diagram.relationships[0].fromCardinality, .exactlyOne)
        XCTAssertEqual(diagram.relationships[0].toCardinality, .oneOrMore)
    }
}
