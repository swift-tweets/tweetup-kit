extension Array where Element: Equatable {
    internal func separated(by separator: Element) -> [[Element]] {
        var separated: [[Element]] = [[]]
        for element in self {
            if element == separator {
                separated.append([])
            } else {
                separated[separated.endIndex - 1].append(element)
            }
        }
        
        return separated
    }
}

extension Array where Element: Hashable {
    internal func trimmingElements(in set: Set<Element>) -> [Element] {
        var trimmed = [Element]()
        var elements = [Element]()
        
        for element in self {
            if set.contains(element) {
                if !trimmed.isEmpty {
                    elements.append(element)
                }
            } else {
                elements.forEach { trimmed.append($0) }
                elements = []
                trimmed.append(element)
            }
        }
        
        return trimmed
    }
}
