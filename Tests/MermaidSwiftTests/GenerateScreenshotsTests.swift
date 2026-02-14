import XCTest
@testable import MermaidSwift

/// Generates example PNG screenshots for the README.
/// Run: swift test --filter GenerateScreenshotsTests
final class GenerateScreenshotsTests: XCTestCase {

    private let outputDir: String = {
        // Navigate from build dir to package root/examples
        let file = #filePath
        let testsDir = (file as NSString).deletingLastPathComponent
        let packageRoot = ((testsDir as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
        return packageRoot + "/examples"
    }()

    override func setUp() {
        super.setUp()
        try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
    }

    func testGenerateFlowchart() throws {
        let data = try MermaidSwift().renderToPNG("""
        flowchart TD
            A[Rectangle] --> B(Rounded)
            B --> C([Stadium])
            C --> D{Diamond}
            D --> E((Circle))
            E --> F>Asymmetric]
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/flowchart.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateSequence() throws {
        let data = try MermaidSwift().renderToPNG("""
        sequenceDiagram
            participant A as Alice
            actor B as Bob
            A->>B: Solid arrow
            A-->>B: Dotted arrow
            A-)B: Async
            A--)B: Dotted async
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/sequence.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGeneratePie() throws {
        let data = try MermaidSwift().renderToPNG("""
        pie title Distribution
            "Category A" : 40
            "Category B" : 35
            "Category C" : 25
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/pie.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateClassDiagram() throws {
        let data = try MermaidSwift().renderToPNG("""
        classDiagram
            class Animal {
                +String name
                #int age
                +makeSound() void
            }
            class Dog {
                +String breed
                +fetch() void
            }
            Dog --|> Animal : inherits
            Dog *-- Collar
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/class.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateStateDiagram() throws {
        let data = try MermaidSwift().renderToPNG("""
        stateDiagram-v2
            [*] --> Idle
            Idle --> Processing : start
            Processing --> Done : finish
            Done --> [*]
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/state.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateGantt() throws {
        let data = try MermaidSwift().renderToPNG("""
        gantt
            title Sprint Plan
            dateFormat YYYY-MM-DD
            section Design
                Wireframes :a1, 2024-01-01, 10d
                Review     :after a1, 5d
            section Development
                Backend    :crit, 2024-01-15, 20d
                Frontend   :active, 2024-01-20, 15d
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/gantt.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateERDiagram() throws {
        let data = try MermaidSwift().renderToPNG("""
        erDiagram
            CUSTOMER ||--o{ ORDER : places
            ORDER ||--|{ LINE-ITEM : contains
            CUSTOMER {
                int id PK
                string name
                string email UK
            }
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/er.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateSubgraph() throws {
        let data = try MermaidSwift().renderToPNG("""
        graph TD
            subgraph Frontend
                A[React] --> B[Next.js]
            end
            subgraph Backend
                C[Node.js] --> D[Express]
            end
            B --> C
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/subgraph.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateStyleDirectives() throws {
        let data = try MermaidSwift().renderToPNG("""
        graph TD
            A[Important]:::highlight --> B[Normal]
            classDef highlight fill:#f96,stroke:#333,stroke-width:2px,color:#fff
            style B fill:#bbf,stroke:#333
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/style.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }

    func testGenerateDarkMode() throws {
        let data = try MermaidSwift.darkMode.renderToPNG("""
        flowchart TD
            A[Hello] --> B[Dark World]
            B --> C{Choice}
            C -->|Yes| D[Option A]
            C -->|No| E[Option B]
        """)
        try data.write(to: URL(fileURLWithPath: "\(outputDir)/dark_mode.png"))
        XCTAssertGreaterThan(data.count, 1000)
    }
}
