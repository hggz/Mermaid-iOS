import XCTest
@testable import MermaidSwift

final class MermaidSwiftIntegrationTests: XCTestCase {

    // MARK: - End-to-End: Parse → Layout → Render → PNG

    func testFlowchartEndToEnd() throws {
        let mermaid = """
        graph TD
            A[Start] --> B{Decision}
            B --> |Yes| C[OK]
            B --> |No| D[Fail]
        """
        let renderer = MermaidSwift()
        let image = try renderer.render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
        let png = try renderer.renderToPNG(mermaid)
        XCTAssertGreaterThan(png.count, 100)
    }

    func testFlowchartLR() throws {
        let mermaid = """
        graph LR
            A --> B --> C
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testSequenceDiagramEndToEnd() throws {
        let mermaid = """
        sequenceDiagram
            Alice->>Bob: Hello Bob
            Bob-->>Alice: Hi Alice
            Alice->>Bob: How are you?
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testPieChartEndToEnd() throws {
        let mermaid = """
        pie title Browsers
            "Chrome" : 65
            "Firefox" : 20
            "Safari" : 15
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testClassDiagramEndToEnd() throws {
        let mermaid = """
        classDiagram
            class Animal {
                +String name
                +makeSound() void
            }
            class Dog {
                +String breed
                +fetch() void
            }
            Dog --|> Animal
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testClassDiagramWithFullRelationships() throws {
        let mermaid = """
        classDiagram
            class Vehicle
            class Car
            class Engine
            class Wheel
            class Driver
            Car --|> Vehicle
            Car *-- Engine
            Car o-- Wheel
            Driver --> Car
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testStateDiagramEndToEnd() throws {
        let mermaid = """
        stateDiagram-v2
            [*] --> Idle
            Idle --> Processing : start
            Processing --> Done : finish
            Done --> [*]
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testStateDiagramWithDescriptions() throws {
        let mermaid = """
        stateDiagram-v2
            [*] --> Active
            state "User is active" as Active
            Active --> Idle : timeout
            Idle --> Active : input
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testGanttChartEndToEnd() throws {
        let mermaid = """
        gantt
            title Project Plan
            dateFormat YYYY-MM-DD
            section Design
                Wireframes    :a1, 2024-01-01, 10d
                Review        :after a1, 5d
            section Development
                Backend       :crit, 2024-01-15, 20d
                Frontend      :2024-01-20, 15d
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testGanttChartTaskStatuses() throws {
        let mermaid = """
        gantt
            section Tasks
                Done task      :done, t1, 2024-01-01, 5d
                Active task    :active, t2, 2024-01-06, 5d
                Critical task  :crit, t3, after t2, 5d
                Normal task    :t4, after t3, 5d
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testERDiagramEndToEnd() throws {
        let mermaid = """
        erDiagram
            CUSTOMER ||--o{ ORDER : places
            ORDER ||--|{ LINE-ITEM : contains
            CUSTOMER {
                string name
                int id PK
            }
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testERDiagramMultipleEntities() throws {
        let mermaid = """
        erDiagram
            CUSTOMER ||--o{ ORDER : places
            ORDER ||--|{ LINE-ITEM : contains
            CUSTOMER {
                int id PK
                string name
                string email UK
            }
            ORDER {
                int id PK
                int customer_id FK
                date created_at
            }
            LINE-ITEM {
                int id PK
                int order_id FK
                string product
                int quantity
            }
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    // MARK: - Subgraphs

    func testFlowchartWithSubgraphs() throws {
        let mermaid = """
        graph TD
            subgraph Frontend
                A[React] --> B[Next.js]
            end
            subgraph Backend
                C[Node.js] --> D[Express]
            end
            B --> C
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    // MARK: - Style Directives

    func testFlowchartWithClassDef() throws {
        let mermaid = """
        graph TD
            A[Important]:::highlight --> B[Normal]
            classDef highlight fill:#f96,stroke:#333,stroke-width:2px,color:#fff
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testFlowchartWithStyleDirective() throws {
        let mermaid = """
        graph TD
            A[One] --> B[Two]
            style A fill:#bbf,stroke:#333
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    // MARK: - Dark Mode

    func testDarkModeFlowchart() throws {
        let mermaid = """
        graph TD
            A[Hello] --> B[World]
        """
        let renderer = MermaidSwift.darkMode
        let image = try renderer.render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testDarkModeSequence() throws {
        let mermaid = """
        sequenceDiagram
            A->>B: test
        """
        let image = try MermaidSwift.darkMode.render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testDarkModeClassDiagram() throws {
        let mermaid = """
        classDiagram
            class Foo {
                +bar() void
            }
        """
        let image = try MermaidSwift.darkMode.render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    // MARK: - Edge Cases

    func testMinimalFlowchart() throws {
        let image = try MermaidSwift().render("graph TD\n    A")
        XCTAssertGreaterThan(image.width, 0)
    }

    func testFlowchartWithComments() throws {
        let mermaid = """
        graph TD
            %% This is a comment
            A[Start] --> B[End]
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    func testMultipleEdgesFromSingleNode() throws {
        let mermaid = """
        graph TD
            A --> B
            A --> C
            A --> D
            A --> E
        """
        let image = try MermaidSwift().render(mermaid)
        XCTAssertGreaterThan(image.width, 0)
    }

    // MARK: - PNG Data Round-Trip

    func testAllDiagramTypesProducePNG() throws {
        let diagrams: [(String, String)] = [
            ("flowchart", "graph TD\n    A --> B"),
            ("sequence", "sequenceDiagram\n    A->>B: hi"),
            ("pie", "pie\n    \"A\" : 50\n    \"B\" : 50"),
            ("class", "classDiagram\n    class A"),
            ("state", "stateDiagram-v2\n    [*] --> A"),
            ("gantt", "gantt\n    section S\n        Task :t1, 2024-01-01, 5d"),
            ("er", "erDiagram\n    A ||--o{ B : has")
        ]

        let renderer = MermaidSwift()
        for (name, mermaid) in diagrams {
            let png = try renderer.renderToPNG(mermaid)
            XCTAssertGreaterThan(png.count, 0, "\(name) PNG should not be empty")

            // Verify PNG magic bytes
            let bytes = [UInt8](png)
            XCTAssertEqual(bytes[0], 0x89, "\(name) PNG magic byte 0")
            XCTAssertEqual(bytes[1], 0x50, "\(name) PNG magic byte 1")
        }
    }
}
