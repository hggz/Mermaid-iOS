# Contributing to Mermaid-iOS

Thanks for your interest in contributing! This project renders [Mermaid](https://mermaid.js.org/) diagrams natively on iOS using pure Swift and CoreGraphics — no JavaScript or WKWebView required.

## Getting Started

1. Fork the repo and clone your fork
2. Install [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
3. Generate the Xcode project: `xcodegen generate`
4. Open `MermaidRenderer.xcodeproj` in Xcode
5. Build and run (⌘R) on an iOS 17+ simulator

## Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Run all tests: `⌘U` in Xcode or `xcodebuild test -scheme MermaidSwiftTests -destination 'platform=iOS Simulator,name=iPhone 17'`
4. Commit with a clear message
5. Open a pull request

## Architecture

```
Sources/
├── MermaidSwift/
│   ├── Model/         # Diagram AST types (FlowchartDiagram, SequenceDiagram, PieChartDiagram)
│   ├── Parser/        # Mermaid DSL → Model (regex-based parser)
│   ├── Layout/        # Model → positioned elements (topological sort, spacing)
│   └── Renderer/      # Positioned elements → CGImage (CoreGraphics)
├── ContentView.swift  # SwiftUI demo app
└── MermaidSwift.swift # Public API facade
```

The pipeline is: **Parse → Layout → Render**

- **Parser**: Converts Mermaid text into typed diagram models
- **Layout**: Computes positions/sizes using topological sort (flowcharts), horizontal spacing (sequence), or angle math (pie)
- **Renderer**: Draws to a CoreGraphics bitmap context at 2x scale

## What to Contribute

### High-Impact Areas

- **New diagram types**: Class diagrams, state diagrams, Gantt charts, ER diagrams
- **Parser improvements**: Subgraphs, styling directives (`style`, `classDef`), notes
- **Layout refinements**: Edge routing to avoid overlaps, better auto-sizing
- **Rendering polish**: Rounded corners, gradient fills, shadow effects, dark mode support

### Good First Issues

- Add support for `graph` keyword as alias for `flowchart`
- Parse `%%` comments mid-line (currently only handles full-line comments)
- Add hexagon node shape (`{{text}}`)
- Support `autonumber` in sequence diagrams

## Code Style

- Swift 5.9, iOS 17+ deployment target
- Use `struct` over `class` where possible
- Keep parsing, layout, and rendering strictly separated
- All public API goes through `MermaidSwift` facade
- Write tests for every new feature (parser tests + integration tests at minimum)

## Testing

Tests are organized into four suites:

| Suite | What it covers |
|-------|---------------|
| `MermaidParserTests` | Parsing all diagram types, edge cases, error handling |
| `DiagramLayoutTests` | Position computation, topological sort, spacing |
| `DiagramRendererTests` | Image generation, PNG export, all shapes/styles |
| `MermaidSwiftIntegrationTests` | End-to-end: text → image, large diagrams, config |

Run all tests:
```bash
xcodebuild test \
  -scheme MermaidSwiftTests \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Pull Request Guidelines

- Keep PRs focused — one feature or fix per PR
- Include tests for new functionality
- Update the README if adding a new diagram type
- Ensure all existing tests pass before submitting

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
