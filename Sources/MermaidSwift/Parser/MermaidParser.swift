import Foundation

/// Parses Mermaid DSL strings into diagram model objects.
///
/// Supports: flowchart, sequenceDiagram, pie, classDiagram, stateDiagram, gantt, erDiagram
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

    public init() {}

    /// Parse a Mermaid DSL string into a typed Diagram.
    public func parse(_ input: String) throws -> Diagram {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.emptyInput }

        let lines = trimmed.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("%%") }

        guard let firstLine = lines.first else { throw ParseError.emptyInput }

        if firstLine.hasPrefix("flowchart") || firstLine.hasPrefix("graph") {
            return try parseFlowchart(lines: lines, header: firstLine)
        } else if firstLine.hasPrefix("sequenceDiagram") {
            return try parseSequenceDiagram(lines: Array(lines.dropFirst()))
        } else if firstLine.hasPrefix("pie") {
            return try parsePieChart(lines: lines, header: firstLine)
        } else if firstLine.hasPrefix("classDiagram") {
            return try parseClassDiagram(lines: Array(lines.dropFirst()))
        } else if firstLine.hasPrefix("stateDiagram") {
            return try parseStateDiagram(lines: Array(lines.dropFirst()))
        } else if firstLine.hasPrefix("gantt") {
            return try parseGanttDiagram(lines: Array(lines.dropFirst()))
        } else if firstLine.hasPrefix("erDiagram") {
            return try parseERDiagram(lines: Array(lines.dropFirst()))
        } else {
            throw ParseError.unknownDiagramType(firstLine)
        }
    }
}

// MARK: - Flowchart Parser

extension MermaidParser {

    private func parseFlowchart(lines: [String], header: String) throws -> FlowchartDiagram {
        let parts = header.split(separator: " ")
        let dirStr = parts.count > 1 ? String(parts[1]) : "TD"
        let direction = FlowchartDiagram.FlowDirection(rawValue: dirStr) ?? .topToBottom

        var nodes: [String: FlowNode] = [:]
        var edges: [FlowEdge] = []
        var subgraphs: [Subgraph] = []
        var classDefs: [String: NodeStyle] = [:]
        var nodeClassMap: [String: String] = [:]

        // Track subgraph nesting
        var subgraphStack: [(id: String, label: String, nodeIds: [String])] = []

        for line in lines.dropFirst() {
            // Skip end keyword
            if line == "end" {
                if let current = subgraphStack.popLast() {
                    subgraphs.append(Subgraph(id: current.id, label: current.label, nodeIds: current.nodeIds))
                }
                continue
            }

            // Subgraph start
            if line.hasPrefix("subgraph ") {
                let rest = String(line.dropFirst("subgraph ".count)).trimmingCharacters(in: .whitespaces)
                // "subgraph id [label]" or "subgraph label"
                let subParts = rest.components(separatedBy: " ")
                let sgId: String
                let sgLabel: String
                if subParts.count > 1 && rest.contains("[") {
                    sgId = subParts[0]
                    // Extract label from brackets if present
                    if let bracketStart = rest.firstIndex(of: "["),
                       let bracketEnd = rest.firstIndex(of: "]") {
                        sgLabel = String(rest[rest.index(after: bracketStart)..<bracketEnd])
                    } else {
                        sgLabel = subParts.dropFirst().joined(separator: " ")
                    }
                } else {
                    sgId = subParts[0]
                    sgLabel = rest
                }
                subgraphStack.append((id: sgId, label: sgLabel, nodeIds: []))
                continue
            }

            // classDef directive: classDef className fill:#f9f,stroke:#333
            if line.hasPrefix("classDef ") {
                if let cd = parseClassDef(line) {
                    classDefs[cd.0] = cd.1
                }
                continue
            }

            // class directive: class nodeA,nodeB className
            if line.hasPrefix("class ") && !line.contains("-->") && !line.contains("---") {
                parseClassDirective(line, into: &nodeClassMap)
                continue
            }

            // style directive: style nodeId fill:#f9f,stroke:#333
            if line.hasPrefix("style ") {
                if let sd = parseStyleDirective(line) {
                    // Store as a unique classDef for this node
                    let uniqueName = "__style_\(sd.0)"
                    classDefs[uniqueName] = sd.1
                    nodeClassMap[sd.0] = uniqueName
                }
                continue
            }

            // Try edge parse
            if let parsed = parseFlowchartEdge(line) {
                for (id, label, shape) in [(parsed.fromId, parsed.fromLabel, parsed.fromShape),
                                           (parsed.toId, parsed.toLabel, parsed.toShape)] {
                    if nodes[id] == nil {
                        nodes[id] = FlowNode(id: id, label: label ?? id, shape: shape ?? .rectangle)
                    }
                    // Add to current subgraph
                    if var current = subgraphStack.last, !current.nodeIds.contains(id) {
                        subgraphStack[subgraphStack.count - 1].nodeIds.append(id)
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
                if !subgraphStack.isEmpty {
                    subgraphStack[subgraphStack.count - 1].nodeIds.append(node.id)
                }
            }

            // Handle :::className on nodes
            if line.contains(":::") {
                let classParts = line.components(separatedBy: ":::")
                if classParts.count == 2 {
                    let nodeRef = classParts[0].trimmingCharacters(in: .whitespaces)
                    let className = classParts[1].trimmingCharacters(in: .whitespaces)
                    let (nodeId, _, _) = parseNodeRef(nodeRef)
                    nodeClassMap[nodeId] = className
                }
            }
        }

        return FlowchartDiagram(
            direction: direction,
            nodes: Array(nodes.values),
            edges: edges,
            subgraphs: subgraphs,
            classDefs: classDefs,
            nodeClassMap: nodeClassMap
        )
    }

    private func parseClassDef(_ line: String) -> (String, NodeStyle)? {
        // classDef className fill:#f9f,stroke:#333,stroke-width:2px,color:#000
        let rest = String(line.dropFirst("classDef ".count)).trimmingCharacters(in: .whitespaces)
        let parts = rest.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return nil }

        let className = String(parts[0])
        let styleStr = String(parts[1])
        let style = parseStyleString(styleStr)
        return (className, style)
    }

    private func parseStyleDirective(_ line: String) -> (String, NodeStyle)? {
        // style nodeId fill:#f9f,stroke:#333
        let rest = String(line.dropFirst("style ".count)).trimmingCharacters(in: .whitespaces)
        let parts = rest.split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return nil }

        let nodeId = String(parts[0])
        let styleStr = String(parts[1])
        let style = parseStyleString(styleStr)
        return (nodeId, style)
    }

    private func parseClassDirective(_ line: String, into map: inout [String: String]) {
        // class nodeA,nodeB className
        let rest = String(line.dropFirst("class ".count)).trimmingCharacters(in: .whitespaces)
        let parts = rest.split(separator: " ")
        guard parts.count >= 2 else { return }

        let className = String(parts.last!)
        let nodeList = parts.dropLast().joined(separator: " ")
        for nodeId in nodeList.split(separator: ",") {
            map[String(nodeId).trimmingCharacters(in: .whitespaces)] = className
        }
    }

    private func parseStyleString(_ str: String) -> NodeStyle {
        var fill: String?
        var stroke: String?
        var strokeWidth: CGFloat?
        var color: String?

        for prop in str.split(separator: ",") {
            let kv = prop.split(separator: ":", maxSplits: 1)
            guard kv.count == 2 else { continue }
            let key = String(kv[0]).trimmingCharacters(in: .whitespaces)
            let value = String(kv[1]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "fill":
                fill = value
            case "stroke":
                stroke = value
            case "stroke-width":
                let numStr = value.replacingOccurrences(of: "px", with: "")
                strokeWidth = CGFloat(Double(numStr) ?? 2)
            case "color":
                color = value
            default:
                break
            }
        }

        return NodeStyle(fill: fill, stroke: stroke, strokeWidth: strokeWidth, color: color)
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

                if rightPart.hasPrefix("|") {
                    if let endPipe = rightPart.dropFirst().firstIndex(of: "|") {
                        edgeLabel = String(rightPart[rightPart.index(after: rightPart.startIndex)..<endPipe])
                        rightPart = String(rightPart[rightPart.index(after: endPipe)...]).trimmingCharacters(in: .whitespaces)
                    }
                }

                // Strip :::className from parts
                let cleanLeft = leftPart.components(separatedBy: ":::").first ?? leftPart
                let cleanRight = rightPart.components(separatedBy: ":::").first ?? rightPart

                let (fromId, fromLabel, fromShape) = parseNodeRef(cleanLeft)
                let (toId, toLabel, toShape) = parseNodeRef(cleanRight)

                return ParsedEdge(
                    fromId: fromId, fromLabel: fromLabel, fromShape: fromShape,
                    toId: toId, toLabel: toLabel, toShape: toShape,
                    edgeLabel: edgeLabel, edgeStyle: style
                )
            }
        }
        return nil
    }

    func parseNodeRef(_ ref: String) -> (id: String, label: String?, shape: FlowNode.NodeShape?) {
        let s = ref.trimmingCharacters(in: .whitespaces)

        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\(\((.+)\)\)$/) {
            return (String(match.1), String(match.2), .circle)
        }
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\(\[(.+)\]\)$/) {
            return (String(match.1), String(match.2), .stadium)
        }
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\{\{(.+)\}\}$/) {
            return (String(match.1), String(match.2), .hexagon)
        }
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\{(.+)\}$/) {
            return (String(match.1), String(match.2), .diamond)
        }
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)>(.+)\]$/) {
            return (String(match.1), String(match.2), .asymmetric)
        }
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\((.+)\)$/) {
            return (String(match.1), String(match.2), .roundedRect)
        }
        if let match = s.firstMatch(of: /^([A-Za-z0-9_]+)\[(.+)\]$/) {
            return (String(match.1), String(match.2), .rectangle)
        }
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

            if line.hasPrefix("actor ") {
                let id = String(line.dropFirst("actor ".count)).trimmingCharacters(in: .whitespaces)
                if !participantSet.contains(id) {
                    participants.append(Participant(id: id, label: id))
                    participantSet.insert(id)
                }
                continue
            }

            if let msg = parseSequenceMessage(line) {
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

        if let titleMatch = header.firstMatch(of: /pie\s+title\s+(.+)/) {
            title = String(titleMatch.1).trimmingCharacters(in: .whitespaces)
        }

        for line in lines.dropFirst() {
            if line.hasPrefix("title ") && title == nil {
                title = String(line.dropFirst("title ".count)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if let match = line.firstMatch(of: /^\s*"(.+?)"\s*:\s*([0-9.]+)\s*$/) {
                let label = String(match.1)
                let value = Double(match.2) ?? 0
                slices.append(PieSlice(label: label, value: value))
            }
        }

        return PieChartDiagram(title: title, slices: slices)
    }
}

// MARK: - Class Diagram Parser

extension MermaidParser {

    private func parseClassDiagram(lines: [String]) throws -> ClassDiagram {
        var classes: [String: ClassDefinition] = [:]
        var relationships: [ClassRelationship] = []
        var currentClass: String? = nil
        var inBlock = false

        for line in lines {
            // End of class block
            if line == "}" && inBlock {
                inBlock = false
                currentClass = nil
                continue
            }

            // Inside class block - parse members
            if inBlock, let className = currentClass {
                if let member = parseClassMember(line) {
                    if member.name.contains("(") {
                        classes[className]?.methods.append(member)
                    } else {
                        classes[className]?.properties.append(member)
                    }
                }
                continue
            }

            // Class block start: "class ClassName {"
            if line.hasPrefix("class ") && line.hasSuffix("{") {
                let name = String(line.dropFirst("class ".count).dropLast())
                    .trimmingCharacters(in: .whitespaces)
                if classes[name] == nil {
                    classes[name] = ClassDefinition(name: name)
                }
                currentClass = name
                inBlock = true
                continue
            }

            // Class with annotation: "class ClassName"
            if line.hasPrefix("class ") && !line.contains("{") && !line.contains(":") {
                let name = String(line.dropFirst("class ".count)).trimmingCharacters(in: .whitespaces)
                if classes[name] == nil {
                    classes[name] = ClassDefinition(name: name)
                }
                continue
            }

            // Annotation: <<interface>> ClassName
            if line.hasPrefix("<<") {
                if let match = line.firstMatch(of: /<<(.+?)>>\s+(.+)/) {
                    let annotation = String(match.1)
                    let className = String(match.2).trimmingCharacters(in: .whitespaces)
                    if classes[className] == nil {
                        classes[className] = ClassDefinition(name: className)
                    }
                    classes[className]?.annotation = annotation
                }
                continue
            }

            // Inline member: "ClassName : +method()"
            if line.contains(" : ") && !line.contains("--") && !line.contains("..") {
                let colonParts = line.components(separatedBy: " : ")
                if colonParts.count >= 2 {
                    let className = colonParts[0].trimmingCharacters(in: .whitespaces)
                    let memberStr = colonParts.dropFirst().joined(separator: " : ").trimmingCharacters(in: .whitespaces)

                    if classes[className] == nil {
                        classes[className] = ClassDefinition(name: className)
                    }

                    if let member = parseClassMember(memberStr) {
                        if member.name.contains("(") {
                            classes[className]?.methods.append(member)
                        } else {
                            classes[className]?.properties.append(member)
                        }
                    }
                }
                continue
            }

            // Relationship
            if let rel = parseClassRelationship(line) {
                // Ensure both classes exist
                for name in [rel.from, rel.to] {
                    if classes[name] == nil {
                        classes[name] = ClassDefinition(name: name)
                    }
                }
                relationships.append(rel)
                continue
            }
        }

        return ClassDiagram(
            classes: Array(classes.values).sorted { $0.name < $1.name },
            relationships: relationships
        )
    }

    private func parseClassMember(_ line: String) -> ClassMember? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        var visibility: ClassMember.Visibility = .public
        var rest = trimmed

        if let first = rest.first {
            switch first {
            case "+": visibility = .public; rest = String(rest.dropFirst())
            case "-": visibility = .private; rest = String(rest.dropFirst())
            case "#": visibility = .protected; rest = String(rest.dropFirst())
            case "~": visibility = .packagePrivate; rest = String(rest.dropFirst())
            default: break
            }
        }

        rest = rest.trimmingCharacters(in: .whitespaces)
        guard !rest.isEmpty else { return nil }

        // Check if it's "Type name" or "name() ReturnType" or just "name"
        let parts = rest.split(separator: " ", maxSplits: 1)
        if rest.contains("(") {
            // Method: name() or name() ReturnType
            let name = rest.contains(" ") ? String(parts[0]) : rest
            let memberType = parts.count > 1 ? String(parts[1]) : nil
            return ClassMember(visibility: visibility, name: name, memberType: memberType)
        } else if parts.count == 2 {
            // Property: Type name
            let memberType = String(parts[0])
            let name = String(parts[1])
            return ClassMember(visibility: visibility, name: name, memberType: memberType)
        } else {
            return ClassMember(visibility: visibility, name: rest, memberType: nil)
        }
    }

    private func parseClassRelationship(_ line: String) -> ClassRelationship? {
        let relationPatterns: [(pattern: String, type: ClassRelationship.ClassRelationType)] = [
            ("..|>", .realization),
            ("<|..", .realization),
            ("<|--", .inheritance),
            ("--|>", .inheritance),
            ("*--", .composition),
            ("--*", .composition),
            ("o--", .aggregation),
            ("--o", .aggregation),
            ("..>", .dependency),
            ("<..", .dependency),
            ("-->", .association),
            ("<--", .association),
            ("--", .association),
        ]

        for (pattern, relType) in relationPatterns {
            guard let range = line.range(of: pattern) else { continue }

            let leftPart = String(line[line.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let rightPart = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)

            // Check for label after " : "
            var toName: String
            var label: String?
            if rightPart.contains(" : ") {
                let labelParts = rightPart.components(separatedBy: " : ")
                toName = labelParts[0].trimmingCharacters(in: .whitespaces)
                label = labelParts.dropFirst().joined(separator: " : ").trimmingCharacters(in: .whitespaces)
            } else {
                toName = rightPart
            }

            // Check for cardinality: "1" ClassName or ClassName "1..*"
            var fromName = leftPart
            var fromCard: String?
            var toCard: String?

            if let match = fromName.firstMatch(of: /^"(.+?)"\s+(.+)$/) {
                fromCard = String(match.1)
                fromName = String(match.2)
            }
            if let match = toName.firstMatch(of: /^(.+?)\s+"(.+?)"$/) {
                toName = String(match.1)
                toCard = String(match.2)
            } else if let match = toName.firstMatch(of: /^"(.+?)"\s+(.+)$/) {
                toCard = String(match.1)
                toName = String(match.2)
            }

            fromName = fromName.trimmingCharacters(in: .whitespaces)
            toName = toName.trimmingCharacters(in: .whitespaces)

            guard !fromName.isEmpty, !toName.isEmpty else { continue }

            // Determine direction
            let isReversed = pattern.hasPrefix("<")
            let from = isReversed ? toName : fromName
            let to = isReversed ? fromName : toName

            return ClassRelationship(
                from: from, to: to, label: label,
                relationshipType: relType,
                fromCardinality: isReversed ? toCard : fromCard,
                toCardinality: isReversed ? fromCard : toCard
            )
        }
        return nil
    }
}

// MARK: - State Diagram Parser

extension MermaidParser {

    private func parseStateDiagram(lines: [String]) throws -> StateDiagram {
        var states: [String: StateNode] = [:]
        var transitions: [StateTransition] = []

        for line in lines {
            // State description: state "description" as s1
            if line.hasPrefix("state ") {
                if let match = line.firstMatch(of: /state\s+"(.+?)"\s+as\s+(\S+)/) {
                    let desc = String(match.1)
                    let id = String(match.2)
                    states[id] = StateNode(id: id, label: id, description: desc)
                } else {
                    let rest = String(line.dropFirst("state ".count)).trimmingCharacters(in: .whitespaces)
                    if !rest.isEmpty && !rest.contains("-->") {
                        let name = rest.replacingOccurrences(of: "\"", with: "")
                        if states[name] == nil {
                            states[name] = StateNode(id: name, label: name)
                        }
                    }
                }
                continue
            }

            // Transition: State1 --> State2 : label
            if line.contains("-->") {
                let parts = line.components(separatedBy: "-->")
                guard parts.count >= 2 else { continue }

                let from = parts[0].trimmingCharacters(in: .whitespaces)
                let rightPart = parts[1].trimmingCharacters(in: .whitespaces)

                var to: String
                var label: String?

                if rightPart.contains(":") {
                    let colonParts = rightPart.components(separatedBy: ":")
                    to = colonParts[0].trimmingCharacters(in: .whitespaces)
                    label = colonParts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                } else {
                    to = rightPart
                }

                // Register states
                let fromId = from == "[*]" ? "[*]" : from
                let toId = to == "[*]" ? "[*]" : to

                if states[fromId] == nil {
                    states[fromId] = StateNode(id: fromId, label: fromId)
                }
                if states[toId] == nil {
                    states[toId] = StateNode(id: toId, label: toId)
                }

                transitions.append(StateTransition(from: fromId, to: toId, label: label))
            }
        }

        return StateDiagram(
            states: Array(states.values).sorted { $0.id < $1.id },
            transitions: transitions
        )
    }
}

// MARK: - Gantt Diagram Parser

extension MermaidParser {

    private func parseGanttDiagram(lines: [String]) throws -> GanttDiagram {
        var title: String?
        var dateFormat: String?
        var sections: [GanttSection] = []
        var currentSection = GanttSection(name: "Default")
        var hasSection = false

        for line in lines {
            if line.hasPrefix("title ") {
                title = String(line.dropFirst("title ".count)).trimmingCharacters(in: .whitespaces)
                continue
            }
            if line.hasPrefix("dateFormat ") {
                dateFormat = String(line.dropFirst("dateFormat ".count)).trimmingCharacters(in: .whitespaces)
                continue
            }
            if line.hasPrefix("section ") {
                if hasSection {
                    sections.append(currentSection)
                }
                let name = String(line.dropFirst("section ".count)).trimmingCharacters(in: .whitespaces)
                currentSection = GanttSection(name: name)
                hasSection = true
                continue
            }
            if line.hasPrefix("axisFormat") || line.hasPrefix("todayMarker") ||
               line.hasPrefix("excludes") || line.hasPrefix("inclusiveEndDates") {
                continue
            }

            // Task: "Task Name :tag1, tag2, ..., start, duration"
            if let task = parseGanttTask(line) {
                if !hasSection {
                    hasSection = true
                }
                currentSection.tasks.append(task)
            }
        }

        if hasSection {
            sections.append(currentSection)
        }

        return GanttDiagram(title: title, dateFormat: dateFormat, sections: sections)
    }

    private func parseGanttTask(_ line: String) -> GanttTask? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Format: "Task Name :metadata"
        guard let colonIdx = trimmed.firstIndex(of: ":") else { return nil }

        let name = String(trimmed[trimmed.startIndex..<colonIdx]).trimmingCharacters(in: .whitespaces)
        let metaStr = String(trimmed[trimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else { return nil }

        var tokens = metaStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        var status: GanttTask.TaskStatus = .normal
        var id: String?
        var afterId: String?
        var startDate: String?
        var duration: String?

        // Parse status flags
        var statusFlags: [String] = []
        while let first = tokens.first, ["done", "active", "crit"].contains(first) {
            statusFlags.append(tokens.removeFirst())
        }

        if statusFlags.contains("crit") && statusFlags.contains("done") {
            status = .criticalDone
        } else if statusFlags.contains("crit") && statusFlags.contains("active") {
            status = .criticalActive
        } else if statusFlags.contains("crit") {
            status = .critical
        } else if statusFlags.contains("done") {
            status = .done
        } else if statusFlags.contains("active") {
            status = .active
        }

        // Remaining tokens: [id], start|after, duration
        for token in tokens {
            if token.hasPrefix("after ") {
                afterId = String(token.dropFirst("after ".count)).trimmingCharacters(in: .whitespaces)
            } else if token.hasSuffix("d") || token.hasSuffix("w") || token.hasSuffix("h") {
                duration = token
            } else if token.contains("-") && token.count >= 8 {
                // Looks like a date
                startDate = token
            } else {
                // Could be an ID
                id = token
            }
        }

        return GanttTask(name: name, id: id, status: status,
                         startDate: startDate, duration: duration, afterId: afterId)
    }
}

// MARK: - ER Diagram Parser

extension MermaidParser {

    private func parseERDiagram(lines: [String]) throws -> ERDiagram {
        var entities: [String: EREntity] = [:]
        var relationships: [ERRelationship] = []
        var currentEntity: String? = nil
        var inBlock = false

        for line in lines {
            // End of entity block
            if line == "}" && inBlock {
                inBlock = false
                currentEntity = nil
                continue
            }

            // Inside entity block - parse attributes
            if inBlock, let entityName = currentEntity {
                if let attr = parseERAttribute(line) {
                    entities[entityName]?.attributes.append(attr)
                }
                continue
            }

            // Entity block: "ENTITY_NAME {"
            if line.hasSuffix("{") && !line.contains("|") {
                let name = String(line.dropLast()).trimmingCharacters(in: .whitespaces)
                if entities[name] == nil {
                    entities[name] = EREntity(name: name)
                }
                currentEntity = name
                inBlock = true
                continue
            }

            // Relationship: ENTITY1 ||--o{ ENTITY2 : label
            if let rel = parseERRelationship(line) {
                for name in [rel.from, rel.to] {
                    if entities[name] == nil {
                        entities[name] = EREntity(name: name)
                    }
                }
                relationships.append(rel)
            }
        }

        return ERDiagram(
            entities: Array(entities.values).sorted { $0.name < $1.name },
            relationships: relationships
        )
    }

    private func parseERAttribute(_ line: String) -> ERAttribute? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: " ")
        guard parts.count >= 2 else { return nil }

        let attrType = String(parts[0])
        let name = String(parts[1])
        var key: ERAttribute.AttributeKey?

        if parts.count >= 3 {
            key = ERAttribute.AttributeKey(rawValue: String(parts[2]))
        }

        return ERAttribute(attributeType: attrType, name: name, key: key)
    }

    private func parseERRelationship(_ line: String) -> ERRelationship? {
        // Pattern: ENTITY1 <left_card>--<right_card> ENTITY2 : "label"
        // Cardinality markers: || (exactly one), |o or o| (zero or one), }| or |{ (one or more), o{ or }o (zero or more)
        let cardinalityPatterns: [(String, ERRelationship.ERCardinality, ERRelationship.ERCardinality)] = [
            ("||--||", .exactlyOne, .exactlyOne),
            ("||--o{", .exactlyOne, .zeroOrMore),
            ("||--|{", .exactlyOne, .oneOrMore),
            ("||--o|", .exactlyOne, .zeroOrOne),
            ("}o--||", .zeroOrMore, .exactlyOne),
            ("}|--||", .oneOrMore, .exactlyOne),
            ("o|--||", .zeroOrOne, .exactlyOne),
            ("o{--||", .zeroOrMore, .exactlyOne),
            ("}o--o{", .zeroOrMore, .zeroOrMore),
            ("}|--o{", .oneOrMore, .zeroOrMore),
            ("o|--o{", .zeroOrOne, .zeroOrMore),
            ("}|--|{", .oneOrMore, .oneOrMore),
        ]

        for (pattern, leftCard, rightCard) in cardinalityPatterns {
            guard let range = line.range(of: pattern) else { continue }

            let leftPart = String(line[line.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let rightPart = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)

            // Extract label after " : "
            var entityName: String
            var label: String

            if rightPart.contains(" : ") {
                let colonParts = rightPart.components(separatedBy: " : ")
                entityName = colonParts[0].trimmingCharacters(in: .whitespaces)
                label = colonParts.dropFirst().joined(separator: " : ")
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\"", with: "")
            } else {
                entityName = rightPart
                label = ""
            }

            guard !leftPart.isEmpty, !entityName.isEmpty else { continue }

            return ERRelationship(
                from: leftPart, to: entityName, label: label,
                fromCardinality: leftCard, toCardinality: rightCard
            )
        }

        return nil
    }
}
