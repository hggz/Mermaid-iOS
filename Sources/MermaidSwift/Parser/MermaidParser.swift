import Foundation

/// Parses Mermaid DSL strings into diagram model objects.
///
/// Supports: flowchart, sequenceDiagram, pie
public struct MermaidParser {

    public enum ParseError: LocalizedError, Equatable {
        case emptyInput
        case unknownDiagramType(String)
        case invalidSyntax(String)

        public var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Empty diagram input"
            case .unknownDiagramType(let type):
                return "Unknown diagram type: \(type)"
            case .invalidSyntax(let detail):
                return "Invalid syntax: \(detail)"
            }
        }
    }

    /// Parse a Mermaid DSL string into a typed Diagram.
    func parse(_ input: String) throws -> Diagram {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.emptyInput }

        let lines = trimmed.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("%%") } // skip comments

        guard let firstLine = lines.first else { throw ParseError.emptyInput }

        if firstLine.hasPrefix("flowchart") || firstLine.hasPrefix("graph") {
            return try parseFlowchart(lines: lines, header: firstLine)
        } else if firstLine.hasPrefix("sequenceDiagram") {
            return try parseSequenceDiagram(lines: Array(lines.dropFirst()))
        } else if firstLine.hasPrefix("pie") {
            return try parsePieChart(lines: lines, header: firstLine)
        } else {
            throw ParseError.unknownDiagramType(firstLine)
        }
    }
}

// MARK: - Flowchart Parser

extension MermaidParser {

    private func parseFlowchart(lines: [String], header: String) throws -> FlowchartDiagram {
        // Parse direction: "flowchart TD" or "graph LR"
        let parts = header.split(separator: " ")
        let dirStr = parts.count > 1 ? String(parts[1]) : "TD"
        let direction = FlowchartDiagram.FlowDirection(rawValue: dirStr) ?? .topToBottom

        var nodes: [String: FlowNode] = [:]
        var edges: [FlowEdge] = []

        for line in lines.dropFirst() {
            if let parsed = parseFlowchartEdge(line) {
                // Auto-create nodes
                for (id, label, shape) in [(parsed.fromId, parsed.fromLabel, parsed.fromShape),
                                           (parsed.toId, parsed.toLabel, parsed.toShape)] {
                    if nodes[id] == nil {
                        nodes[id] = FlowNode(id: id, label: label ?? id, shape: shape ?? .rectangle)
                    }
                }
                edges.append(FlowEdge(
                    from: parsed.fromId,
                    to: parsed.toId,
                    label: parsed.edgeLabel,
                    style: parsed.edgeStyle
                ))
            } else if let node = parseFlowchartNode(line) {
                nodes[node.id] = node
            }
        }

        return FlowchartDiagram(
            direction: direction,
            nodes: Array(nodes.values),
            edges: edges
        )
    }

    private struct ParsedEdge {
        let fromId: String
        let fromLabel: String?
        let fromShape: FlowNode.NodeShape?
        let toId: String
        let toLabel: String?
        let toShape: FlowNode.NodeShape?
        let edgeLabel: String?
        let edgeStyle: FlowEdge.EdgeStyle
    }

    private func parseFlowchartEdge(_ line: String) -> ParsedEdge? {
        // Match patterns like: A --> B, A[Foo] -->|label| B{Bar}, A -.-> B, A ==> B
        let edgePatterns: [(pattern: String, style: FlowEdge.EdgeStyle)] = [
            ("==>", .thick),
            ("-.->", .dotted),
            ("~~~", .invisible),
            ("-->", .solid),
        ]

        for (pattern, style) in edgePatterns {
            if let range = line.range(of: pattern) {
                let leftPart = String(line[line.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                var rightPart = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                var edgeLabel: String? = nil

                // Check for edge label: |label|
                if rightPart.hasPrefix("|") {
                    if let endPipe = rightPart.dropFirst().firstIndex(of: "|") {
                        edgeLabel = String(rightPart[rightPart.index(after: rightPart.startIndex)..<endPipe])
                        rightPart = String(rightPart[rightPart.index(after: endPipe)...]).trimmingCharacters(in: .whitespaces)
                    }
                }

                let (fromId, fromLabel, fromShape) = parseNodeRef(leftPart)
                let (toId, toLabel, toShape) = parseNodeRef(rightPart)

                return ParsedEdge(
                    fromId: fromId, fromLabel: fromLabel, fromShape: fromShape,
                    toId: toId, toLabel: toLabel, toShape: toShape,
                    edgeLabel: edgeLabel, edgeStyle: style
                )
            }
        }
        return nil
    }

    /// Parse a node reference like `A`, `A[Label]`, `A(Label)`, `A{Label}`, `A((Label))`, `A([Label])`
    private func parseNodeRef(_ ref: String) -> (id: String, label: String?, shape: FlowNode.NodeShape?) {
        let s = ref.trimmingCharacters(in: .whitespaces)

        // ((label)) — circle
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\(\((.+)\)\)$/) {
            return (String(match.1), String(match.2), .circle)
        }
        // ([label]) — stadium
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\(\[(.+)\]\)$/) {
            return (String(match.1), String(match.2), .stadium)
        }
        // {{label}} — hexagon
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\{\{(.+)\}\}$/) {
            return (String(match.1), String(match.2), .hexagon)
        }
        // {label} — diamond
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\{(.+)\}$/) {
            return (String(match.1), String(match.2), .diamond)
        }
        // >label] — asymmetric
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)>(.+)\]$/) {
            return (String(match.1), String(match.2), .asymmetric)
        }
        // (label) — rounded rect
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\((.+)\)$/) {
            return (String(match.1), String(match.2), .roundedRect)
        }
        // [label] — rectangle
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\[(.+)\]$/) {
            return (String(match.1), String(match.2), .rectangle)
        }
        // Plain ID
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)$/) {
            return (String(match.1), nil, nil)
        }

        return (s, nil, nil)
    }

    private func parseFlowchartNode(_ line: String) -> FlowNode? {
        let (id, label, shape) = parseNodeRef(line)
        guard label != nil || shape != nil else { return nil }
        return FlowNode(id: id, label: label ?? id, shape: shape ?? .rectangle)
    }
}

// MARK: - Sequence Diagram Parser

extension MermaidParser {

    private func parseSequenceDiagram(lines: [String]) throws -> SequenceDiagram {
        var participants: [Participant] = []
        var participantSet: Set<String> = []
        var messages: [Message] = []

        for line in lines {
            // participant declarations: "participant Alice" or "participant A as Alice"
            if line.hasPrefix("participant ") {
                let rest = String(line.dropFirst("participant ".count))
                let parts = rest.components(separatedBy: " as ")
                let id: String
                let label: String
                if parts.count >= 2 {
                    id = parts[0].trimmingCharacters(in: .whitespaces)
                    label = parts[1].trimmingCharacters(in: .whitespaces)
                } else {
                    id = rest.trimmingCharacters(in: .whitespaces)
                    label = id
                }
                if !participantSet.contains(id) {
                    participants.append(Participant(id: id, label: label))
                    participantSet.insert(id)
                }
                continue
            }

            // actor declarations: "actor Alice"
            if line.hasPrefix("actor ") {
                let id = String(line.dropFirst("actor ".count)).trimmingCharacters(in: .whitespaces)
                if !participantSet.contains(id) {
                    participants.append(Participant(id: id, label: id))
                    participantSet.insert(id)
                }
                continue
            }

            // Messages: "Alice->>Bob: Hello"
            if let msg = parseSequenceMessage(line) {
                // Auto-register participants
                for pid in [msg.from, msg.to] {
                    if !participantSet.contains(pid) {
                        participants.append(Participant(id: pid, label: pid))
                        participantSet.insert(pid)
                    }
                }
                messages.append(msg)
            }
        }

        return SequenceDiagram(participants: participants, messages: messages)
    }

    private func parseSequenceMessage(_ line: String) -> Message? {
        let arrowPatterns: [(pattern: String, style: Message.MessageStyle)] = [
            ("-->>", .dottedArrow),
            ("->>",  .solidArrow),
            ("--x",  .dottedCross),
            ("-x",   .solidCross),
            ("-->",  .dottedLine),
            ("->",   .solidLine),
        ]

        for (pattern, style) in arrowPatterns {
            guard let arrowRange = line.range(of: pattern) else { continue }

            let from = String(line[line.startIndex..<arrowRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let afterArrow = String(line[arrowRange.upperBound...]).trimmingCharacters(in: .whitespaces)

            // Split on first ": " for target and message text
            let colonParts = afterArrow.components(separatedBy: ": ")
            guard colonParts.count >= 2 else { continue }

            let to = colonParts[0].trimmingCharacters(in: .whitespaces)
            let text = colonParts.dropFirst().joined(separator: ": ").trimmingCharacters(in: .whitespaces)

            guard !from.isEmpty, !to.isEmpty else { continue }

            return Message(from: from, to: to, text: text, style: style)
        }
        return nil
    }
}

// MARK: - Pie Chart Parser

extension MermaidParser {

    private func parsePieChart(lines: [String], header: String) throws -> PieChartDiagram {
        var title: String? = nil
        var slices: [PieSlice] = []

        // "pie title My Title"
        if let titleMatch = header.firstMatch(of: /pie\s+title\s+(.+)/) {
            title = String(titleMatch.1).trimmingCharacters(in: .whitespaces)
        }

        for line in lines.dropFirst() {
            // "title My Title" on its own line
            if line.hasPrefix("title ") && title == nil {
                title = String(line.dropFirst("title ".count)).trimmingCharacters(in: .whitespaces)
                continue
            }

            // Match: "Label" : value
            if let match = line.firstMatch(of: /^\s*"(.+?)"\s*:\s*([0-9.]+)\s*$/) {
                let label = String(match.1)
                let value = Double(match.2) ?? 0
                slices.append(PieSlice(label: label, value: value))
            }
        }

        return PieChartDiagram(title: title, slices: slices)
    }
}
