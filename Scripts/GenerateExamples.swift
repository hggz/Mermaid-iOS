import MermaidSwift
import Foundation

let renderer = MermaidSwift()

let examples: [(String, String)] = [
    ("examples/flowchart.png", """
    flowchart TD
        A[Rectangle] --> B(Rounded)
        B --> C([Stadium])
        C --> D{Diamond}
        D --> E((Circle))
        E --> F>Asymmetric]
    """),
    ("examples/sequence.png", """
    sequenceDiagram
        participant A as Alice
        actor B as Bob
        A->>B: Solid arrow
        A-->>B: Dotted arrow
        A-)B: Async
        A--)B: Dotted async
    """),
    ("examples/pie.png", """
    pie title Distribution
        "Category A" : 40
        "Category B" : 35
        "Category C" : 25
    """)
]

// Create examples directory
let fm = FileManager.default
try? fm.createDirectory(atPath: "examples", withIntermediateDirectories: true)

for (path, diagram) in examples {
    do {
        let data = try renderer.renderToPNG(diagram)
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
        print("✓ \(path) (\(data.count) bytes)")
    } catch {
        print("✗ \(path): \(error)")
    }
}
