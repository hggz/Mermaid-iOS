import MermaidSwift
import Foundation

let renderer = MermaidSwift()
let darkRenderer = MermaidSwift.darkMode

let examples: [(String, String, MermaidSwift)] = [
    ("examples/flowchart.png", """
    flowchart TD
        A[Rectangle] --> B(Rounded)
        B --> C([Stadium])
        C --> D{Diamond}
        D --> E((Circle))
        E --> F>Asymmetric]
    """, renderer),
    ("examples/sequence.png", """
    sequenceDiagram
        participant A as Alice
        actor B as Bob
        A->>B: Solid arrow
        A-->>B: Dotted arrow
        A-)B: Async
        A--)B: Dotted async
    """, renderer),
    ("examples/pie.png", """
    pie title Distribution
        "Category A" : 40
        "Category B" : 35
        "Category C" : 25
    """, renderer),
    ("examples/class.png", """
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
    """, renderer),
    ("examples/state.png", """
    stateDiagram-v2
        [*] --> Idle
        Idle --> Processing : start
        Processing --> Done : finish
        Done --> [*]
    """, renderer),
    ("examples/gantt.png", """
    gantt
        title Sprint Plan
        dateFormat YYYY-MM-DD
        section Design
            Wireframes :a1, 2024-01-01, 10d
            Review     :after a1, 5d
        section Development
            Backend    :crit, 2024-01-15, 20d
            Frontend   :active, 2024-01-20, 15d
    """, renderer),
    ("examples/er.png", """
    erDiagram
        CUSTOMER ||--o{ ORDER : places
        ORDER ||--|{ LINE-ITEM : contains
        CUSTOMER {
            int id PK
            string name
            string email UK
        }
    """, renderer),
    ("examples/subgraph.png", """
    graph TD
        subgraph Frontend
            A[React] --> B[Next.js]
        end
        subgraph Backend
            C[Node.js] --> D[Express]
        end
        B --> C
    """, renderer),
    ("examples/style.png", """
    graph TD
        A[Important]:::highlight --> B[Normal]
        classDef highlight fill:#f96,stroke:#333,stroke-width:2px,color:#fff
        style B fill:#bbf,stroke:#333
    """, renderer),
    ("examples/dark_mode.png", """
    flowchart TD
        A[Hello] --> B[Dark World]
        B --> C{Choice}
        C -->|Yes| D[Option A]
        C -->|No| E[Option B]
    """, darkRenderer),
]

// Create examples directory
let fm = FileManager.default
try? fm.createDirectory(atPath: "examples", withIntermediateDirectories: true)

for (path, diagram, r) in examples {
    do {
        let data = try r.renderToPNG(diagram)
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
        print("✓ \(path) (\(data.count) bytes)")
    } catch {
        print("✗ \(path): \(error)")
    }
}
