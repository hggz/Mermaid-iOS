import XCTest
@testable import MermaidSwift

final class MermaidSwiftIntegrationTests: XCTestCase {

    let mermaid = MermaidSwift()

    // MARK: - End-to-End Rendering

    func testRenderFlowchart() throws {
        let image = try mermaid.render("""
        flowchart TD
            A[Start] --> B{Is valid?}
            B -->|Yes| C[Process]
            B -->|No| D[Reject]
            C --> E[Done]
            D --> E
        """)

        XCTAssertTrue(image.width > 0)
        XCTAssertTrue(image.height > 0)
    }

    func testRenderSequenceDiagram() throws {
        let image = try mermaid.render("""
        sequenceDiagram
            participant Client
            participant Server
            participant DB
            Client->>Server: GET /users
            Server->>DB: SELECT * FROM users
            DB-->>Server: ResultSet
            Server-->>Client: 200 OK
        """)

        XCTAssertTrue(image.width > 0)
        XCTAssertTrue(image.height > 0)
    }

    func testRenderPieChart() throws {
        let image = try mermaid.render("""
        pie title Platform Distribution
            "iOS" : 45
            "Android" : 40
            "Web" : 15
        """)

        XCTAssertTrue(image.width > 0)
        XCTAssertTrue(image.height > 0)
    }

    func testRenderToPNG() throws {
        let pngData = try mermaid.renderToPNG("""
        flowchart LR
            A --> B --> C
        """)

        XCTAssertTrue(pngData.count > 100) // Should be a reasonable PNG
        // Verify PNG header
        let header = [UInt8](pngData.prefix(8))
        XCTAssertEqual(header[0], 0x89)
        XCTAssertEqual(header[1], 0x50)
        XCTAssertEqual(header[2], 0x4E)
        XCTAssertEqual(header[3], 0x47)
    }

    func testParseOnly() throws {
        let diagram = try mermaid.parse("""
        sequenceDiagram
            Alice->>Bob: Hello
        """)

        XCTAssertTrue(diagram is SequenceDiagram)
        let seq = diagram as! SequenceDiagram
        XCTAssertEqual(seq.messages.count, 1)
    }

    // MARK: - Error Cases

    func testRenderEmptyInput() {
        XCTAssertThrowsError(try mermaid.render(""))
    }

    func testRenderUnsupportedType() {
        XCTAssertThrowsError(try mermaid.render("gantt\n  title Schedule"))
    }

    // MARK: - Custom Config

    func testCustomConfig() throws {
        var config = LayoutConfig.default
        config.nodeWidth = 200
        config.nodeHeight = 80
        config.fontSize = 18

        let custom = MermaidSwift(config: config)
        let image = try custom.render("flowchart TD\n  A[Big Node] --> B[Another]")

        XCTAssertTrue(image.width > 0)
    }

    // MARK: - Complex Diagrams

    func testLargeFlowchart() throws {
        var lines = ["flowchart TD"]
        for i in 0..<20 {
            lines.append("    N\(i)[Node \(i)]")
        }
        for i in 0..<19 {
            lines.append("    N\(i) --> N\(i+1)")
        }

        let image = try mermaid.render(lines.joined(separator: "\n"))
        XCTAssertTrue(image.width > 0)
        XCTAssertTrue(image.height > 0)
    }

    func testManyParticipants() throws {
        var lines = ["sequenceDiagram"]
        let names = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank"]
        for name in names {
            lines.append("    participant \(name)")
        }
        for i in 0..<(names.count - 1) {
            lines.append("    \(names[i])->>\(names[i+1]): Message \(i+1)")
        }

        let image = try mermaid.render(lines.joined(separator: "\n"))
        XCTAssertTrue(image.width > 0)
    }

    func testManyPieSlices() throws {
        var lines = ["pie title Many Slices"]
        for i in 1...10 {
            lines.append("    \"Slice \(i)\" : \(i * 5)")
        }

        let image = try mermaid.render(lines.joined(separator: "\n"))
        XCTAssertTrue(image.width > 0)
    }
}
