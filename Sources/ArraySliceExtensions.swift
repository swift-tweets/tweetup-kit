extension ArraySlice {
    internal var headAndTail: (Element?, ArraySlice<Element>) {
        guard count > 0 else {
            return (nil, [])
        }
        return (first, self[(startIndex + 1) ..< endIndex])
    }
}
